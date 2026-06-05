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
  # Hibernate writes to the encrypted swap PARTITION (luks ... a6b327e9, prio
  # -2) ahead of the swapfile (prio -3), and resumeDevice below names that same
  # partition. This path resumed reliably from March through 2026-05-06.
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
  # image lands on the partition (prio -2) ahead of the swapfile (prio -3), so
  # an offset here is meaningless and was the stale 38834176 (real swapfile
  # first extent is 73617408, irrelevant to a partition resume).
  boot.resumeDevice = "/dev/disk/by-uuid/a6b327e9-d898-49a9-8858-9891cc770e82";
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 15779; # MBs
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
  # suspends). KNOWN LIMITATION (journal 2026-06-03): this timer is frozen
  # while the system is in S3, so a lid-closed laptop that drains entirely
  # while asleep never fires it and loses the session. suspend-then-hibernate
  # was the attempted fix for that, but it depends on a resume path that
  # doesn't work here — revisit only after resume is verified (see note above).
  systemd.services.hibernate-on-low-battery = {
    description = "Hibernate when battery is critically low";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'if [ $(cat /sys/class/power_supply/BAT*/capacity) -le 5 ] && [ $(cat /sys/class/power_supply/AC*/online) -eq 0 ]; then /run/current-system/sw/bin/systemctl hibernate; fi'";
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

  # --- Post-resume fixup: fingerprint reader --------------------------------
  # fprintd 1.94.5 + Synaptics 06cb:00bd leak /net/reactivated/Fprint/Device/N
  # dbus objects across suspend cycles: libfprint sometimes misses the USB
  # device-removed event when the kernel re-enumerates the sensor after
  # resume, so fprintd's GetDefaultDevice (g_list_last in manager.c) may
  # return a stale Device/N — breaking hyprlock fingerprint auth with
  # "Device was already claimed". Restarting fprintd on resume clears
  # the accumulated state. Debian #979143 tracks the same hardware.
  #
  # IMPORTANT (2026-06-05): this MUST bind to the real systemd sleep units, NOT
  # "post-resume.target" — that target does not exist (LoadState=not-found), so
  # the previous wantedBy/after=post-resume.target meant this service NEVER ran
  # (confirmed: zero fprintd-resume entries in journal history). systemd runs
  # systemd-suspend.service / systemd-hibernate.service / the hybrid variants
  # for the whole sleep cycle; ordering After= them and pulling in via WantedBy=
  # them makes this fire once on the way back up from any sleep type.
  systemd.services.fprintd-resume = {
    description = "Restart fprintd after resume to clear stale device state";
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
      ExecStart = "${pkgs.systemd}/bin/systemctl restart fprintd.service";
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
