{ config, pkgs, lib, ... }:

# =============================================================================
# SSHFS — tile:~/tmp/shared mounted on obsidian
# =============================================================================
# Mounts joshua@tile:/home/joshua/tmp/shared at /mnt/tile.
# tile is reached over Tailscale (MagicDNS name `tile`), so this works from
# anywhere both machines are on the tailnet, not just the LAN.
#
# ON-DEMAND, NOT AT BOOT. `noauto` + `x-systemd.automount` means systemd
# creates an automount unit and only dials tile when something first touches
# the directory. Mounting at boot would be wrong twice over: the network (and
# tailscaled) is not up that early, and a laptop that boots away from the
# tailnet would block or fail the mount every time.
#
# It unmounts itself again after 10 minutes idle, so a roaming laptop is not
# left holding a dead SSH connection across suspend/network changes.
{
  # Puts mount.sshfs on the mount-helper path. environment.systemPackages is
  # NOT sufficient: systemd mount units run with a minimal PATH and `mount -t
  # sshfs` has to be able to find the helper. system.fsPackages is the hook
  # that exists for exactly this.
  system.fsPackages = [ pkgs.sshfs ];

  # allow_other below needs this; without it FUSE refuses the option and the
  # mount fails outright.
  programs.fuse.userAllowOther = true;

  # The automount unit will create the mount point, but creating it here means
  # the path exists and is joshua-owned even before the first access.
  systemd.tmpfiles.rules = [
    "d /mnt/tile 0755 joshua users -"
  ];

  # --- Self-healing ----------------------------------------------------------
  # A FUSE mount whose transport dies does NOT recover on its own. sshfs's
  # `reconnect` only helps while the mount is alive; once the endpoint is gone
  # every access returns ENOTCONN ("Transport endpoint is not connected"), and
  # systemd's automount will NOT redial because, as far as it is concerned,
  # something is already mounted there. It stays broken until the dead mount is
  # removed by hand.
  #
  # Two things kill it in practice, so both are handled:
  #   1. sleep      — the SSH session dies while the machine is frozen.
  #   2. the tailnet going away mid-session — key expiry, deauth, a network
  #      change. Observed 2026-09-24: tailscale was deauthed and the mount went
  #      to ENOTCONN and stayed there.
  #
  # The fix in both cases is the same: unmount, and let the automount redial on
  # the next access. Nothing has to know WHY it died.

  # (1) Drop the mount on the way into any sleep, mirroring fprintd-presleep in
  # power.nix. Cheaper than detecting the breakage afterwards.
  systemd.services.tile-mount-presleep = {
    description = "Unmount /mnt/tile before sleep so it cannot go stale";
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
      # Lazy unmount: never block going to sleep on a server that is already
      # unreachable. `-` prefix so a missing mount is not a failure.
      ExecStart = "-${pkgs.util-linux}/bin/umount -l /mnt/tile";
    };
  };

  # (2) Catch everything else. Clears a dead endpoint within a minute so the
  # next `cd /mnt/tile` just works.
  systemd.services.tile-mount-healthcheck = {
    description = "Clear /mnt/tile if its sshfs transport has died";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "tile-mount-healthcheck" ''
        set -u

        # Do nothing unless an sshfs mount is actually present. This is read
        # straight from mountinfo rather than by touching /mnt/tile, because
        # touching the path would trigger the automount and dial tile on every
        # single tick -- the check must not create the traffic it is policing.
        ${pkgs.gnugrep}/bin/grep -q " /mnt/tile fuse.sshfs " /proc/self/mountinfo || exit 0

        # Probe THROUGH the mount, not at it. `stat -f /mnt/tile` was the first
        # attempt and is wrong: the mountpoint is also an autofs node, so the
        # statfs is answered by autofs and returns success even while the sshfs
        # underneath is dead -- verified 2026-09-24 against a genuinely broken
        # mount. `stat /mnt/tile/.` is a getattr routed through FUSE, so a dead
        # transport surfaces as ENOTCONN. It is also far lighter than a
        # directory listing, which would drag the whole remote listing over the
        # link every tick. The timeout covers a hung (rather than dead) link.
        if ${pkgs.coreutils}/bin/timeout 5 ${pkgs.coreutils}/bin/stat /mnt/tile/. >/dev/null 2>&1; then
          exit 0
        fi

        echo "/mnt/tile transport is dead; unmounting so the automount can redial"
        ${pkgs.util-linux}/bin/umount -l /mnt/tile 2>/dev/null \
          || ${pkgs.fuse3}/bin/fusermount3 -u -z /mnt/tile 2>/dev/null \
          || true
      '';
    };
  };

  systemd.timers.tile-mount-healthcheck = {
    description = "Periodically check the /mnt/tile sshfs transport";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
      Unit = "tile-mount-healthcheck.service";
    };
  };

  fileSystems."/mnt/tile" = {
    device = "joshua@tile:/home/joshua/tmp/shared";
    fsType = "sshfs";
    options = [
      # --- when to mount -----------------------------------------------------
      "noauto"
      "x-systemd.automount"
      "_netdev"
      # NO x-systemd.idle-timeout: the healthcheck below statfs's the mount
      # every minute, which counts as access and would keep resetting the
      # idle clock anyway. The healthcheck is what tears down a dead mount
      # now, so an idle timer would only add a second, competing mechanism.
      "x-systemd.mount-timeout=20s"  # fail fast when tile is unreachable

      # --- ssh identity ------------------------------------------------------
      # The mount runs as ROOT, so nothing here can be inferred from joshua's
      # environment: the key and the known_hosts file both have to be named
      # explicitly, or the mount dies on "Permission denied (publickey)" /
      # "Host key verification failed" with root's empty known_hosts.
      "IdentityFile=/home/joshua/.ssh/id_ed25519"
      "UserKnownHostsFile=/home/joshua/.ssh/known_hosts"
      "StrictHostKeyChecking=accept-new"

      # --- ownership ---------------------------------------------------------
      # Without uid/gid every file shows up owned by root, because that is who
      # holds the FUSE mount. 1000:100 is joshua:users.
      "uid=1000"
      "gid=100"
      "allow_other"

      # --- surviving a roaming laptop ---------------------------------------
      # reconnect re-establishes the SSH session after a network change or a
      # resume; the keepalives detect a dead peer in ~45s instead of hanging.
      "reconnect"
      "ServerAliveInterval=15"
      "ServerAliveCountMax=3"
    ];
  };
}
