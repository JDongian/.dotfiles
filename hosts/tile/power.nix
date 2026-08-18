{ config, pkgs, lib, ... }:

# =============================================================================
# POWER MANAGEMENT — central module for tile (ThinkPad T490s)
# =============================================================================
# Single place for everything that decides what happens when the machine is
# idle, the lid closes, or it goes to sleep. The ONE piece that cannot live
# here is the per-session idle ladder (dim → lock → screen-off), because that
# is a Hyprland/home-manager dotfile: see dotfiles/hypr/hypridle.conf. That
# file's header points back to this module so the two stay legible together.
#
# Layered model, outermost (hardware) to innermost (session):
#   1. powerManagement.enable      — base suspend/resume infrastructure
#   2. swapDevices + resumeDevice   — where a hibernation image is written/read
#   3. logind HandleLidSwitch      — what a lid close does
#   4. hibernate-on-low-battery    — the actual hibernate trigger (timer)
#   5. fprintd-resume hook         — post-resume fixup (fingerprint reader)
#   6. udev charge/autosuspend     — per-device power quirks
#   (7. hypridle idle ladder       — lives in hypridle.conf, cross-referenced)
#
# TODO (deferred, decide separately):
#   - thermald + TLP battery charge thresholds (40/80) exist on `gravel` but
#     NOT here. tile would benefit from both. See hosts/gravel/hardware.nix.
#   - hypridle has a commented-out 600s idle→suspend listener; an idle *open*
#     laptop currently never suspends (only lid-close sleeps). Decide if wanted.
# =============================================================================

{
  # https://nixos.wiki/wiki/Laptop
  powerManagement.enable = true;

  # --- Hibernation -----------------------------------------------------------
  # https://nixos.wiki/wiki/Hibernation
  #
  # HOW RESUME WORKS HERE (evidenced from the journal, boots Jan–Jun 2026):
  # resume is the CLASSIC script-initrd path. NixOS emits a `resume=` kernel
  # param from boot.resumeDevice and the script initrd resumes from it.
  # Hibernate writes to the encrypted swap PARTITION (luks ... a6b327e9).
  # The partition IS listed as a swapDevice (priority 0, lowest) so the
  # kernel can write hibernate images to it, but normal paging goes to the
  # swapfile (priority 10) first. This keeps the partition empty for hibernate.
  # resumeDevice below names the same partition.
  # This path resumed reliably from March through 2026-05-06.
  #
  # DO NOT set boot.initrd.systemd.enable = true. When it was turned on
  # (2026-05-17) resume SILENTLY BROKE: with systemd-initrd, NixOS stops
  # emitting `resume=` on the cmdline and relies on the
  # systemd-hibernate-resume-generator instead. The generator DID find the
  # image (journal: "Reported hibernation image: UUID=a6b327e9 offset=0") but
  # systemd-hibernate-resume.service failed with result 'dependency' — the
  # encrypted swap partition is a LUKS volume that isn't unlocked early enough
  # in the systemd initrd for the resume service to reach it. From 2026-05-17
  # on, every boot cmdline carried no resume= and the machine cold-booted
  # instead of resuming. The 2026-06-04 power.nix refactor inherited this
  # broken state and mislabeled it "working"; removing initrd.systemd.enable
  # restores the script path. See memory hibernation_resume_param.md.
  #
  # resumeDevice points at the swap PARTITION a6b327e9 (verified live: it
  # resolves to /dev/dm-1, the decrypted luks-d2e857c5 swap). This matches the
  # known-good boot of 2026-05-06, whose cmdline was
  # `resume=/dev/disk/by-uuid/a6b327e9-...` and which resumed correctly.
  #
  # CORRECTED 2026-06-05: the old value dc99dc0b-... resolves to NO device on
  # disk. Under the script initrd, NixOS emits resumeDevice verbatim as the
  # `resume=` kernel param, and stage-1 skips resume entirely when that device
  # is absent — so it would have cold-booted. (It only "worked" historically on
  # boots that happened to carry resume=a6b327e9 or a bare resume_offset, not
  # dc99dc0b.) No resume_offset: offsets apply only to swapfile targets, and the
  # image lands on the partition (low-priority swap device kept empty for
  # hibernate), so an offset is meaningless. No resume_offset needed.
  boot.resumeDevice = "/dev/disk/by-uuid/a6b327e9-d898-49a9-8858-9891cc770e82";
  swapDevices = [
    {
      # Hibernate target — must stay swapon'd for the kernel to write images.
      # Priority 0 (lowest used) so normal paging fills the swapfile first.
      device = "/dev/disk/by-uuid/a6b327e9-d898-49a9-8858-9891cc770e82";
      priority = 0;
    }
    {
      device = "/var/lib/swapfile";
      size = 15779; # MBs
      priority = 10; # higher = paged to first, keeping the partition free
    }
  ];

  # --- Lid close: suspend ----------------------------------------------------
  # Renamed in nixos-unstable: lidSwitch → settings.Login.HandleLidSwitch.
  # Anchored to the March 2026 (860b561) behavior: plain suspend on lid close,
  # with hibernation driven by the low-battery timer below. The 2026-06-04
  # refactor had switched this to suspend-then-hibernate, which depends on a
  # working resume path — and resume was broken (see the hibernation note
  # above). Reverting to suspend + the timer restores the known-good setup.
  services.logind.settings.Login.HandleLidSwitch = "suspend";

  # Hibernate when the battery is critically low and on battery power. This is
  # the actual hibernate trigger in the March-anchored setup (the lid only
  # suspends). If hibernate fails (e.g. swap space issue), falls back to
  # suspend so the machine at least stops draining battery.
  #
  # KNOWN LIMITATION: this timer is frozen while the system is in S3, so a
  # lid-closed laptop that drains entirely while asleep never fires it.
  # suspend-then-hibernate would fix that — revisit once resume is verified.
  #
  # FIXED 2026-06-24: the swap partition had higher priority (-2) than the
  # swapfile (-3), so the kernel paged into the partition first. Under memory
  # pressure it filled up, and "systemctl hibernate" was rejected with "Not
  # enough suitable swap space". Fix: partition priority 0 (lowest), swapfile
  # priority 10 (highest) — paging fills the swapfile; partition stays empty.
  # Fallback: if hibernate still fails, the script suspends instead of dying.
  systemd.services.hibernate-on-low-battery = {
    description = "Hibernate when battery is critically low";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ $(cat /sys/class/power_supply/BAT*/capacity) -le 5 ] && [ $(cat /sys/class/power_supply/AC*/online) -eq 0 ]; then /run/current-system/sw/bin/systemctl hibernate || /run/current-system/sw/bin/systemctl suspend; fi'";
    };
  };

  systemd.timers.hibernate-on-low-battery = {
    description = "Check battery percentage and hibernate if needed";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "1min"; # Check every minute
      Unit = "hibernate-on-low-battery.service";
    };
  };

  # --- Fingerprint reader across suspend/resume -----------------------------
  # fprintd 1.94.5 + Synaptics 06cb:00bd break hyprlock fingerprint auth across
  # sleep in two ways: (a) libfprint sometimes misses the USB device-removed
  # event when the sensor re-enumerates on resume, leaving a stale
  # /net/reactivated/Fprint/Device/N that GetDefaultDevice (g_list_last in
  # manager.c) then hands out — "Device was already claimed"; and (b) hyprlock
  # survives sleep as ONE long-lived process and, on PrepareForSleep(false),
  # gets exactly ONE shot at re-claim + re-start-verify. hyprlock has NO retry
  # (upstream hyprlock #768/#577), so if that single claim fails the reader is
  # dead until you type the password. Debian #979143 tracks the same hardware.
  #
  # PRIOR APPROACH (2026-06-05..08-18) restarted fprintd After= the sleep unit.
  # That fired at the exact moment hyprlock was re-arming: fprintd went down
  # mid-claim, hyprlock's one attempt failed silently, reader stayed dead. The
  # journal shows the tell — healthy resumes log "claimed device / started
  # verifying"; raced resumes are MISSING those two lines. So the old fixup was
  # itself causing a share of the failures it meant to fix.
  #
  # NEW APPROACH — don't race, be tolerant (verified live 2026-08-18):
  #   * fprintd is Type=dbus / BusName=net.reactivated.Fprint with a D-Bus
  #     system-service file, i.e. it AUTO-ACTIVATES on first client contact.
  #     Confirmed: from `inactive`, a single `fprintd-list` call flips it to
  #     `active`. So we don't need it running — hyprlock's own claim spawns it.
  #   * fprintd-presleep: STOP fprintd on the way INTO any sleep, so no stale
  #     instance can survive the USB re-enumeration. Nothing to race on resume.
  #   * fprintd-resume: on the way back up, POLL — kick a fresh activation and
  #     confirm the device is genuinely healthy (exactly one Device, no
  #     "(deleted)" usb fds), retrying for ~10s. Whether hyprlock's claim lands
  #     before or after this, it meets a clean, claimable fprintd. "Keep
  #     trying" replaces "restart once and hope the timing is right."
  systemd.services.fprintd-presleep = {
    description = "Stop fprintd before sleep so no stale device survives resume";
    wantedBy = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    before = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      # `stop` is a no-op if it is already inactive (the common case, since it
      # is D-Bus-activated and idles off). --no-block would let sleep proceed
      # before the stop completes, so stay blocking here.
      ExecStart = "${pkgs.systemd}/bin/systemctl stop fprintd.service";
    };
  };

  systemd.services.fprintd-resume = {
    description = "Poll fprintd back to a healthy claimable state after resume";
    wantedBy = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    after = [
      "systemd-suspend.service"
      "systemd-hibernate.service"
      "systemd-hybrid-sleep.service"
      "systemd-suspend-then-hibernate.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      # Restart fprintd ONCE up front to drop any instance that survived the
      # USB re-enumeration with a stale Device/N, then POLL for health without
      # hammering it: each round just triggers D-Bus (re)activation via a
      # cheap `fprintd-list` client call — NOT another `systemctl restart`,
      # which trips systemd's StartLimit rate-limiter (learned the hard way:
      # restarting in a tight loop fails with "start attempted too often").
      # Healthy == exactly one "Device at ..." line AND no "(deleted)" usb fds
      # lingering in the fprintd process. Up to ~10s, then leave it to hyprlock's
      # own claim to re-activate a clean instance on demand.
      #
      # PATH must include gnugrep + coreutils explicitly — writeShellScript does
      # not inherit a login PATH, and procps does NOT provide grep.
      ExecStart = pkgs.writeShellScript "fprintd-resume" ''
        set -u
        PATH=${pkgs.systemd}/bin:${pkgs.fprintd}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.procps}/bin
        # Clear any StartLimit state from prior churn, then one clean restart.
        systemctl reset-failed fprintd.service 2>/dev/null || true
        systemctl restart fprintd.service || true
        for i in $(seq 1 20); do
          sleep 0.5
          # `fprintd-list` is itself a D-Bus client, so it re-activates fprintd
          # if it idled off — this is the "keep trying" without a restart storm.
          out=$(fprintd-list joshua 2>/dev/null || true)
          ndev=$(printf '%s\n' "$out" | grep -c 'Device at' || true)
          pid=$(pidof fprintd 2>/dev/null || true)
          zombies=0
          if [ -n "$pid" ]; then
            zombies=$(ls -l /proc/"$pid"/fd/ 2>/dev/null | grep -c 'usb.*(deleted)' || true)
          fi
          if [ "$ndev" = "1" ] && [ "$zombies" = "0" ]; then
            echo "fprintd healthy after $i poll(s): 1 device, no zombie fds"
            exit 0
          fi
          echo "poll $i: ndev=$ndev zombies=$zombies — retrying"
        done
        echo "fprintd not confirmed healthy after 20 polls; leaving to on-demand activation"
        exit 0
      '';
    };
  };

  # --- Per-device power quirks (udev) ---------------------------------------
  services.udev.extraRules = ''
    # Auto-fast-charge Apple MFi devices (iPhone/iPad). The kernel
    # apple-mfi-fastcharge driver registers the power_supply with
    # initial charge_type="Trickle" (500 mA, USB 2.0 default). This
    # rule flips it to "Fast" (~2500 mA) on every (re)connect.
    ACTION=="add|change", SUBSYSTEM=="power_supply", \
      DRIVERS=="apple-mfi-fastcharge", \
      ATTR{charge_type}="Fast"

    # Synaptics fingerprint reader (06cb:00bd): disable USB autosuspend so
    # the kernel doesn't power it down between scans (causes stalls on
    # next claim). The bulk of fprintd's stale-device problems come from
    # system suspend/resume, not idle autosuspend — see the
    # fprintd-resume.service above for that.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00bd", ATTR{power/control}="on"
  '';
}
