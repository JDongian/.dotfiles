{ config, pkgs, lib, ... }:

# =============================================================================
# POWER MANAGEMENT — central module for obsidian (ThinkPad X1 Carbon 7th gen)
# =============================================================================
# PORTED FROM hosts/tile/power.nix. The logic, and especially the hard-won
# comments explaining WHY each knob is set, are tile's — keep them in sync.
# The ONE substantive difference is device naming, explained under
# "Hibernation" below and in disko-obsidian.nix.
#
# Single place for everything that decides what happens when the machine is
# idle, the lid closes, or it goes to sleep. The ONE piece that cannot live
# here is the per-session idle ladder (dim → lock → screen-off), because that
# is a Hyprland/home-manager dotfile: see dotfiles/hypr/hypridle.conf.
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
# NOT deferred here (unlike tile): thermald and TLP charge thresholds are on
# from day one — see hosts/obsidian/hardware.nix.
# =============================================================================

{
  # DOWNSTREAM: thinkpower (~/work/thinkpower) prefers `upower -i` over raw
  # sysfs for battery state, and /var/lib/upower/history-*.dat is the only
  # battery series on this machine. Turning this off silently degrades that
  # tool to instantaneous sysfs values and stops the history accumulating —
  # nothing in this repo would otherwise record that dependency.
  services.upower.enable = true;

  # --- Hibernation -----------------------------------------------------------
  # https://nixos.wiki/wiki/Hibernation
  #
  # DEVICE NAMING — the one place obsidian deliberately diverges from tile.
  # tile points resumeDevice at a raw UUID (a6b327e9...) because tile was
  # installed BY HAND: nothing ever assigned GPT partition names, so
  # `/dev/disk/by-partlabel/` there lists only EFI and root with NO entry for
  # its swap partition, and its LUKS mappers carry auto `luks-<uuid>` names.
  # by-uuid was the only stable handle tile could have used.
  #
  # obsidian is partitioned by disko, which assigns the LUKS mapper name
  # declaratively (see disko-obsidian.nix: name = "cryptswap"). That makes
  # /dev/mapper/cryptswap knowable BEFORE the disk exists, so this file could
  # be written in full ahead of the install with no post-install UUID patching
  # and no placeholder to forget. It is exactly as deterministic as by-uuid.
  #
  # INITRD FLAVOR — read this before "fixing" anything here.
  # We do NOT set boot.initrd.systemd.enable either way; obsidian takes the
  # nixpkgs default, which is now TRUE (systemd initrd). That is deliberate,
  # and it contradicts an older warning you may find in hosts/tile/power.nix
  # and in the notes, so here is the evidence as of 2026-09-22:
  #
  #   - tile IS running a systemd initrd right now. Its journal for the
  #     current boot shows `systemd[1]: Reached target Initrd Root Device`,
  #     which only a systemd initrd emits.
  #   - Hibernation works there anyway: `Starting Resume from hibernation...`
  #     followed by `Finished Resume from hibernation`, and 14 kernel
  #     `PM: hibernation: hibernation exit` events over Sep 4-18 2026.
  #   - `resume=` IS still emitted on the cmdline under systemd-initrd on
  #     current nixpkgs; the claim that it stops being emitted no longer holds.
  #
  # WHAT THE OLD WARNING WAS ABOUT (still worth knowing): on 2026-05-17 tile
  # turned this on and resume SILENTLY BROKE. systemd-hibernate-resume.service
  # failed with result 'dependency' because the encrypted swap was a LUKS
  # volume not unlocked early enough in the systemd initrd for the resume
  # service to reach it. That was a real failure, but it was specific to the
  # nixpkgs of that era and has since been fixed upstream — the successful
  # resumes above are on a LUKS swap under a systemd initrd, which is exactly
  # the configuration that used to fail.
  #
  # So: do not force this to false as a superstition. If resume ever breaks
  # again, VERIFY first (see below) rather than assuming this is the cause.
  #
  # No resume_offset: offsets apply only to swapFILE targets, and the image
  # lands on the partition (kept empty via the priority split below).
  #
  # VERIFY AFTER INSTALL: `cat /proc/cmdline` must contain
  # `resume=/dev/mapper/cryptswap`. If it does not, resume is NOT working no
  # matter what the hibernate side appears to do.
  boot.resumeDevice = "/dev/mapper/cryptswap";

  # The swap PARTITION itself is declared by disko (priority 0). Only the
  # swapFILE is added here, at HIGH priority.
  #
  # WHY THE SPLIT: tile, 2026-06-24 — the partition had higher priority than
  # the swapfile, so the kernel paged into the partition first. Under memory
  # pressure it filled, and `systemctl hibernate` was refused outright with
  # "Not enough suitable swap space". Paging must fill the FILE; the partition
  # must stay empty to hold a hibernation image.
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16500; # MBs — sized against 16 GB RAM, matching tile's ~15.8 GB
      priority = 10; # higher = paged to first, keeping the partition free
    }
  ];

  # --- Lid close: suspend-then-hibernate -------------------------------------
  # Renamed in nixos-unstable: lidSwitch → settings.Login.HandleLidSwitch.
  #
  # CHANGED 2026-09-24, on obsidian ONLY (tile stays on plain "suspend" until
  # this is proven here).
  #
  # WHAT THIS FIXES: the low-battery timer below does not run while the system
  # is in S3, so a lid-closed laptop that drained flat never hibernated and the
  # session was lost. That timer covers the AWAKE case; this covers the ASLEEP
  # case. They complement each other — keep both.
  #
  # WHY IT IS SAFE TO ENABLE NOW. The 2026-06-04 refactor set exactly this and
  # was reverted because suspend-then-hibernate depends on a working resume
  # path and resume was broken at the time. That condition no longer holds:
  #   - tile: 14 `PM: hibernation: hibernation exit` events, Sep 4-18 2026
  #     (see the hibernation note above)
  #   - obsidian: hibernate + resume exercised on the current boot
  # Verify before trusting it further — see RISK below.
  #
  # WHY NO HibernateDelaySec. systemd 261 (>= 253) makes suspend-then-hibernate
  # battery-aware when the delay is left UNSET: it sets an RTC alarm, wakes,
  # measures the actual discharge rate, and hibernates when the battery is
  # nearly gone. A fixed delay would be a guess at that instead. Leaving
  # sleep.conf at its defaults is the feature, not an omission.
  #
  # The fingerprint sleep hooks further down already list
  # systemd-suspend-then-hibernate.service in wantedBy/before/after, so the
  # reader re-arms on this path exactly as it does on plain suspend.
  #
  # RISK / VERIFICATION: close the lid on battery and leave it long enough to
  # cross the hibernate point, then confirm on wake:
  #   journalctl -b | grep -E "hibernation exit|Finished Resume from hibernation"
  # and that the session and lock screen came back intact. If resume ever
  # regresses, set this back to "suspend" — the low-battery timer alone is the
  # known-good fallback.

  # On wall power there is no battery to run out, so plain suspend: no periodic
  # wake-ups, and an instant resume when the lid opens.

  # --- Power button: suspend on wall power, hibernate on battery ---------------
  # A short press never powers off (the logind default): it is the
  # save-your-work action, and a stray press costs a resume instead of a
  # session. (This button was soup-damaged and cleaned in Sep 2026; if it ever
  # fires spuriously again, set HandlePowerKey back to "ignore" and drop the
  # acpid handler — the Super+Shift+Q fuzzel menu covers intentional shutdowns.)
  #
  # WHY acpid RATHER THAN logind. logind exposes a power-source variant for
  # exactly one control, the lid (HandleLidSwitchExternalPower); every key
  # handler is a single value. So logind is set to "ignore" and becomes a pure
  # event router, and the decision moves to a script that can read anything.
  # Both must not act, or the button fires twice.
  services.logind.settings.Login.HandlePowerKey = "ignore";

  services.acpid = {
    enable = true;
    # `read` is a shell builtin, so this needs nothing on PATH but systemctl.
    # Hibernate falls back to suspend for the same reason the low-battery
    # script does: a refused hibernate must not leave the press doing nothing.
    # The decision lives in policy.toml [button.power]; acpid only routes.
    # THINKPOWER_POLICY is explicit because acpid runs as root, where HOME
    # would point at /root and the policy would not be found.
    powerEventCommands = ''
      THINKPOWER_POLICY=/home/joshua/work/thinkpower/config/policy.toml \
        /home/joshua/.local/bin/thinkpower event power
    '';
  };

  # --- Lock-screen responsiveness (InhibitDelayMaxSec) -----------------------
  # Cuts the visible "warning screen" gap between hyprlock starting and the
  # lock surface actually painting.
  #
  # MEASURED 2026-08-24: hyprlock's start->"Locking session" gap is bimodal —
  # either ~0-1s or EXACTLY 10s, never in between. A round 10s is a timeout,
  # not contention. It decomposes into two 5s halves:
  #
  #   1. hypridle holds a logind DELAY inhibitor while running lock_cmd, and
  #      hyprlock blocks on the session state hypridle is holding. logind
  #      breaks the deadlock at InhibitDelayMaxSec (default 5s), logging
  #      "Delay lock is active (PID .../hypridle) but inhibitor timeout is
  #      reached." Every observed 10s lock has this line ~5s in; no 0s lock
  #      does. That correlation is what identifies this half.
  #   2. hyprlock then spends another ~5s in its own fprintd `Claim`, which
  #      blocks its event loop BEFORE the first frame is drawn — upstream
  #      hyprlock #543 ("Fingerprint can block hyprlock startup resulting in
  #      the recovery screen flashing"), fixed by #544 but NOT in any release:
  #      v0.9.6 (2026-07-18) is still latest and is what we run. So there is
  #      no version bump available for this half.
  #
  # Dropping InhibitDelayMaxSec to 1s removes ~4s of half 1. It does NOT fix
  # half 2 (that needs the upstream fix, or option C in the note below).
  #
  # WHY 1s IS SAFE: this cap only bounds how long logind waits for DELAY
  # inhibitors before proceeding with sleep/lock. Our only delay inhibitor is
  # hypridle's, whose before_sleep_cmd is a single `loginctl lock-session`
  # that completes in milliseconds. It does NOT affect BLOCK inhibitors, and
  # it does not shorten how long the fprintd-presleep/-resume services get
  # (those are ordered systemd units, not inhibitors).
  services.logind.settings.Login.InhibitDelayMaxSec = 1;

  # Two-stage low-battery response, on battery power only:
  #
  #   <= 5%  rest the screen  — lock the session and DPMS the panel off. Buys
  #                             runtime at the point where every watt counts,
  #                             and makes the state obvious if you look over.
  #   <= 4%  hibernate        — the actual save-your-work action.
  #
  # WHY 5% RESTS THE SCREEN RATHER THAN SUSPENDING: this timer does not run
  # while the system is in S3 (the KNOWN LIMITATION below). Suspending at 5%
  # would therefore freeze the timer and the 4% hibernate would NEVER fire --
  # the machine would sit in S3 until the battery died outright and the RAM
  # image was lost. Blanking the panel keeps the system running, so the 4%
  # check still happens.
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
    description = "Rest the screen at 5% battery, hibernate at 4%";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Thresholds and actions live in policy.toml [charge].
      ExecStart = pkgs.writeShellScript "low-battery-action" ''
        THINKPOWER_POLICY=/home/joshua/work/thinkpower/config/policy.toml \
          /home/joshua/.local/bin/thinkpower event charge
      '';
    };
  };

  # Re-apply the system half of the policy at boot: the logind drop-in and
  # the charge thresholds. Ordered after TLP because TLP writes charge
  # thresholds when it starts, and policy must have the last word.
  systemd.services.thinkpower-apply = {
    description = "Apply thinkpower system policy";
    after = [ "tlp.service" "systemd-logind.service" ];
    wants = [ "tlp.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "thinkpower-apply-system" ''
        THINKPOWER_POLICY=/home/joshua/work/thinkpower/config/policy.toml \
          /home/joshua/.local/bin/thinkpower apply --system
      '';
    };
  };

  systemd.timers.hibernate-on-low-battery = {
    description = "Check battery percentage for the low-battery actions";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnUnitActiveSec = "1min"; # Check every minute
      Unit = "hibernate-on-low-battery.service";
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

    # Synaptics fingerprint reader: disable USB autosuspend so the kernel
    # doesn't power it down between scans (causes stalls on next claim). The
    # bulk of fprintd's stale-device problems come from system suspend/resume,
    # not idle autosuspend — see the fprintd-resume.service above for that.
    #
    # BROADENED vs tile: tile pins the exact product id 06cb:00bd. X1C7 units
    # ship several Synaptics sensors (00bd, 00df, 00c9, 0100 are all seen in
    # the wild), and a rule pinned to the wrong id silently does nothing —
    # you would only notice as intermittent post-resume scan stalls. Matching
    # the VENDOR (06cb) covers every variant; 06cb is Synaptics, and the only
    # 06cb device in this laptop is the fingerprint reader, so this is not
    # over-broad in practice.
    #
    # To tighten: run `lsusb | grep -i synaptics` on obsidian and pin the id.
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{power/control}="on"
  '';
}
