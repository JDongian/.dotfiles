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
  # ===========================================================================
  # DEFERRED — "option C": collapse the three hyprlock start paths into one
  # ===========================================================================
  # IMPLEMENT THIS IF the lock-screen gap is still objectionable after the
  # InhibitDelayMaxSec=1 change above. Measure first: compare
  #   journalctl | grep -E "Started Hyprlock|Locking session"
  # A remaining ~5s gap means upstream hyprlock #543 (the blocking fprintd
  # `Claim`) is the only thing left, and that is what this addresses.
  #
  # WHAT IS WRONG TODAY
  # hyprlock gets started three different ways, with no coordination:
  #   1. hypridle lock_cmd        -> systemctl --user start hyprlock.service
  #   2. hypridle before_sleep_cmd -> loginctl lock-session -> (1) again
  #   3. hypridle after_sleep_cmd  -> systemctl --user try-restart hyprlock
  # Path 3 exists solely to RE-ARM THE FINGERPRINT READER on resume, because
  # hyprlock 0.9.6 has no fprint re-claim retry (upstream #711/#577): an
  # instance that lived across suspend gets exactly one claim attempt and
  # fails silently. See the fprintd comment block below for that history.
  #
  # The cost of path 3 is that on resume there are briefly TWO hyprlock
  # instances. Observed 2026-08-24 12:58: the OUTGOING instance (388391) fired
  # a last `Claim` at fprintd from an already-dead D-Bus connection, fprintd
  # sat in a failing authorization round-trip against that ghost
  # ("NameHasNoOwner"), and that blocked fprintd's own shutdown — which in
  # turn blocked `systemctl restart fprintd` inside fprintd-resume, stretching
  # a normally-1.1s service to 10.98s. The incoming instance (388641) then sat
  # waiting on a reader that was not claimable yet.
  #
  # WHAT TO DO INSTEAD
  # Kill the old instance BEFORE sleep rather than restarting it after, so the
  # ghost-claim window never exists:
  #   a. Add hyprlock to the fprintd-presleep stop list (or add a sibling
  #      hyprlock-presleep user service ordered Before=systemd-suspend.service)
  #      so the pre-suspend instance is gone while the session is still sane.
  #   b. Set Restart=always + RestartSec=0 on systemd.user.services.hyprlock
  #      (home.nix ~line 73; currently Restart=on-failure) so systemd brings a
  #      FRESH instance straight back up. A fresh instance claims + starts
  #      verifying within ~1s every time — verified across every "Started
  #      Hyprlock" in the journal.
  #   c. Then DELETE the try-restart from after_sleep_cmd in
  #      dotfiles/hypr/hypridle.conf, leaving only `hyprctl dispatch dpms on`.
  #      Path 3 disappears; only paths 1/2 remain, and they are the same path.
  #
  # WHY NOT JUST DELETE PATH 3 (option "B")
  # Because (a) and (b) are what preserve the fingerprint. Removing the
  # try-restart on its own reintroduces exactly the silent-fingerprint-failure
  # regression documented in the fprintd block below and in the
  # fprintd_resume_workaround memory note. Do NOT do c without a and b.
  #
  # RISK / VERIFICATION
  # This touches the lock path, so a mistake means either no lock screen on
  # resume (security) or no fingerprint (annoyance). Verify across at least 3
  # suspend/resume cycles AND one lid-close cycle:
  #   - a lock surface is present immediately on wake (never a bare desktop),
  #   - hyprlock logs "fprint: claimed device" + "started verifying" within ~1s,
  #   - the start->"Locking session" gap is under ~1s,
  #   - no "Authorization denied ... NameHasNoOwner" from fprintd.
  # Keep the previous generation bootable while testing.
  #
  # ALTERNATIVE THAT MAKES THIS MOOT: if hyprlock ever ships the #543 fix
  # (blocking `Claim` moved off the event loop / into a thread — merged as
  # #544 but unreleased as of v0.9.6, 2026-07-18), bump the package and
  # re-measure before implementing any of the above.
  # ===========================================================================

  # --- hyprlock PAM: no pam_fprintd (hyprlock claims fprintd natively) -------
  # ROOT CAUSE, found 2026-08-28 15:00: hyprlock was claiming the fingerprint
  # device TWICE, from two independent D-Bus clients inside the SAME process,
  # and they raced each other:
  #   1. pam_fprintd — first `auth` module in /etc/pam.d/hyprlock. hyprlock's
  #      startup calls g_pAuth->start(), which runs the PAM stack, so
  #      pam_fprintd claims the device and starts verifying on ITS connection.
  #   2. hyprlock's own fprint code (fingerprint:enabled = true in
  #      hyprlock.conf) — claims on a DIFFERENT connection moments later and
  #      loses:
  #        15:00:29.327 hyprlock: PAM: Place your right index finger  (1 wins)
  #        15:00:29.775 hyprlock: could not claim device, [AlreadyInUse] (2 loses)
  #      hyprlock's own handler then believes it has no device, which produces
  #      the contradictory pair seen on every bad resume: VerifyStop ->
  #      "Device already in use by another user" while VerifyStart -> "Device
  #      was not claimed before use". The reader sits armed-but-unusable until
  #      PAM's 30s "Verification timed out". On 2026-08-28 that locked the
  #      session for 3min13s.
  #
  # WHY THIS SURFACED ONLY AFTER a86c535: the old fprintd-resume did an
  # unconditional `systemctl restart fprintd`, which happened to tear the
  # daemon down BETWEEN the two claims, so claim 2 landed on a fresh daemon.
  # The double-claim was always there; the restart was masking it with a race
  # (while causing its own failures — see the fprintd-resume comment below).
  #
  # RULED OUT by direct test, do not re-chase: fprintd DOES release a claim
  # when the claiming peer dies (it calls g_bus_watch_name /
  # _fprint_device_client_vanished; verified live — a claim taken by a
  # short-lived `busctl` is already gone once that process exits). So this was
  # never a stale claim orphaned by the outgoing hyprlock instance; the
  # competitor is inside the NEW process.
  #
  # FIX: drop pam_fprintd from hyprlock's stack and let hyprlock's native
  # fingerprint support be the single claimant. hyprlock.conf already has
  # `fingerprint:enabled = true` plus ready/present/retry messages, so this
  # keeps the per-touch UI feedback; it is pam_fprintd that is redundant here.
  # Bonus: pam_fprintd is also what made g_pAuth->start() block on a COLD
  # fprintd D-Bus activation during startup, which is the other half of the
  # blank-lock-screen delay.
  #
  # NOTE this is hyprlock ONLY. `sudo`, login, greetd etc. keep pam_fprintd.
  security.pam.services.hyprlock.fprintAuth = false;

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
      # POLL FIRST, restart only if actually unhealthy. Rewritten 2026-08-27
      # after this service was caught DESTROYING hyprlock's fingerprint claim.
      #
      # ROOT CAUSE (evidenced, two resumes 2026-08-26 11:50 and 2026-08-27 01:30):
      # hyprlock's startup calls g_pAuth->start() BEFORE it logs "Running on
      # Hyprland", and /etc/pam.d/hyprlock has pam_fprintd as the FIRST auth
      # module. So every lock synchronously D-Bus-activates net.reactivated.Fprint
      # during startup. fprintd-presleep leaves fprintd stopped across suspend,
      # so on resume that activation is a COLD start — and it queues behind the
      # unconditional `systemctl restart fprintd` this service used to issue.
      # Result: hyprlock blocked ~4.3s in PAM (blank lock screen), and then the
      # restart tore the daemon down at the exact moment hyprlock claimed it:
      #   01:30:45.634 hyprlock: fprint: using device path .../Device/0
      #   01:30:45.649 fprintd:  Deactivated successfully
      #   01:30:45.651 hyprlock: could not claim device, [NoReply]
      #                          Remote peer disconnected
      # (At 11:50 the claim SUCCEEDED and was destroyed 1ms later —
      # "User destroyed open device! Not cleaning up properly!". Same cause,
      # 15ms difference in outcome.) Both times this service then reported
      # "fprintd healthy after 1 poll(s)", because it measured daemon health
      # and not whether it had just invalidated somebody's claim.
      #
      # TWO CHANGES:
      #  1. PRE-WARM. Activate fprintd immediately via a cheap `fprintd-list`
      #     so it is already running when hyprlock's PAM stack asks ~4s later.
      #     A cold D-Bus activation measured 373ms standalone; the damage came
      #     from it queueing behind a restart, not from the activation itself.
      #  2. RESTART ONLY IF UNHEALTHY. The health check below already detects
      #     precisely the stale-device case the restart was written for, so
      #     run it FIRST and keep the restart as the repair path rather than
      #     the default path. On both observed resumes fprintd was healthy, so
      #     this makes the common case a no-op and the claim survives.
      #
      # Healthy == exactly one "Device at ..." line AND no "(deleted)" usb fds
      # lingering in the fprintd process. Restart at most ONCE (never in a
      # loop: that trips systemd's StartLimit — "start attempted too often").
      #
      # PATH must include gnugrep + coreutils explicitly — writeShellScript does
      # not inherit a login PATH, and procps does NOT provide grep.
      ExecStart = pkgs.writeShellScript "fprintd-resume" ''
        set -u
        PATH=${pkgs.systemd}/bin:${pkgs.fprintd}/bin:${pkgs.coreutils}/bin:${pkgs.gnugrep}/bin:${pkgs.procps}/bin

        # Clear any StartLimit state left over from prior churn so that IF we
        # do need the repair restart below, it is allowed to run.
        systemctl reset-failed fprintd.service 2>/dev/null || true

        # check_health: echoes "ok" when fprintd presents exactly one device and
        # holds no stale (deleted) usb fds. `fprintd-list` is itself a D-Bus
        # client, so calling it ACTIVATES fprintd if it is not running — that is
        # the pre-warm (change 1) as well as the probe.
        check_health() {
          out=$(fprintd-list joshua 2>/dev/null || true)
          ndev=$(printf '%s\n' "$out" | grep -c 'Device at' || true)
          pid=$(pidof fprintd 2>/dev/null || true)
          zombies=0
          if [ -n "$pid" ]; then
            zombies=$(ls -l /proc/"$pid"/fd/ 2>/dev/null | grep -c 'usb.*(deleted)' || true)
          fi
          [ "$ndev" = "1" ] && [ "$zombies" = "0" ] && echo ok
        }

        # PRE-WARM + FIRST CHECK. Do this before considering any restart: on a
        # healthy resume this is the whole job, fprintd ends up warm for
        # hyprlock's PAM activation, and nothing is torn down underneath it.
        if [ -n "$(check_health)" ]; then
          echo "fprintd healthy on first check (pre-warmed, no restart needed)"
          exit 0
        fi

        # Not healthy: give a slow USB re-enumeration a chance to settle before
        # escalating to the disruptive repair.
        for i in $(seq 1 6); do
          sleep 0.5
          if [ -n "$(check_health)" ]; then
            echo "fprintd healthy after $i poll(s) without restart"
            exit 0
          fi
        done

        # REPAIR PATH (was previously the default): a genuinely stale instance
        # survived resume. Restart ONCE, then poll again.
        echo "fprintd still unhealthy after pre-warm polls; restarting once"
        systemctl restart fprintd.service || true
        for i in $(seq 1 14); do
          sleep 0.5
          if [ -n "$(check_health)" ]; then
            echo "fprintd healthy $i poll(s) after repair restart"
            exit 0
          fi
        done
        echo "fprintd not confirmed healthy after repair; leaving to on-demand activation"
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
