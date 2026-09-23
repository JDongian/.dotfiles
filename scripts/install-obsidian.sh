#!/usr/bin/env bash
# Install NixOS (host: obsidian) onto a ThinkPad X1 Carbon 7th gen.
#
# Runs from the custom installer ISO. The config repo and the saved Wi-Fi
# profiles are embedded in the image; PACKAGES come from cache.nixos.org, so
# this needs a network connection. The baked-in Wi-Fi profiles mean the ISO
# normally associates with a known network by itself -- the script checks and
# tells you what to do if it has not.
#
# DESTRUCTIVE: wipes the target disk entirely. Confirms before doing so.
set -euo pipefail

DISK="${DISK:-/dev/nvme0n1}"
REPO_SRC="/etc/nixos-repo"
MNT="/mnt"

die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || die "run as root (sudo $0)"
[ -b "$DISK" ] || die "$DISK is not a block device. Set DISK=/dev/... if the internal disk enumerates differently (check: lsblk -d)."
[ -d "$REPO_SRC" ] || die "$REPO_SRC missing — not booted from the obsidian installer ISO?"

# --- Guard: never wipe the USB we booted from ------------------------------
# Resolve the device backing the live medium and refuse if it matches $DISK.
live_src="$(findmnt -no SOURCE /iso 2>/dev/null || findmnt -no SOURCE / 2>/dev/null || true)"
if [ -n "$live_src" ]; then
  live_disk="$(lsblk -no PKNAME "$live_src" 2>/dev/null || true)"
  if [ -n "$live_disk" ] && [ "/dev/$live_disk" = "$DISK" ]; then
    die "$DISK is the installer USB itself. Refusing to wipe it."
  fi
fi

cat <<WARN

  ============================================================
   About to COMPLETELY ERASE: $DISK
  ============================================================
WARN
lsblk -o NAME,SIZE,TYPE,MODEL "$DISK" || true
echo
read -rp "Type ERASE to continue: " confirm
[ "$confirm" = "ERASE" ] || die "aborted"

echo "==> Partitioning + encrypting via disko (you will set the LUKS passphrase)"
# --mode disko = destroy, format, mount. Reads the layout from the embedded
# repo, so the ESP/swap/root names match what hosts/obsidian expects.
disko --mode disko "$REPO_SRC/disko-obsidian.nix" --argstr device "$DISK"

echo "==> Verifying disko produced the expected stable mapper names"
# power.nix hardcodes /dev/mapper/cryptswap for resumeDevice. If that name is
# absent the installed system will boot but never resume, so fail loudly NOW
# rather than discovering it after the first hibernate.
[ -e /dev/mapper/cryptswap ] || die "/dev/mapper/cryptswap missing after disko"
[ -e /dev/mapper/cryptroot ] || die "/dev/mapper/cryptroot missing after disko"
findmnt -no TARGET "$MNT" >/dev/null || die "disko did not mount $MNT"

echo "==> Copying config repo to $MNT/etc/nixos"
mkdir -p "$MNT/etc/nixos"
cp -a "$REPO_SRC/." "$MNT/etc/nixos/"
# wifi-secrets/ is gitignored, so it is absent from a clean checkout but
# present in the ISO payload; either way the copy above carries what exists.

echo "==> Installing Wi-Fi profiles"
wifi_src="$REPO_SRC/wifi-secrets"
if [ -d "$wifi_src" ]; then
  install -d -m 0700 "$MNT/etc/NetworkManager/system-connections"
  # -m 0600 is REQUIRED: NetworkManager ignores any profile that is
  # group- or world-readable, silently, with no error in the UI.
  find "$wifi_src" -name '*.nmconnection' -exec \
    install -m 0600 -t "$MNT/etc/NetworkManager/system-connections" {} +
  n=$(find "$MNT/etc/NetworkManager/system-connections" -name '*.nmconnection' | wc -l)
  echo "    installed $n Wi-Fi profile(s)"
else
  echo "    none staged (run scripts/stage-wifi.sh before building the ISO)"
fi

echo "==> Checking network (packages come from the binary cache)"
if ! curl -fsS --max-time 10 https://cache.nixos.org/nix-cache-info >/dev/null 2>&1; then
  echo
  echo "    No route to cache.nixos.org."
  echo "    The saved Wi-Fi profiles should have auto-connected. To fix by hand:"
  echo "      nmcli device wifi list"
  echo "      nmcli device wifi connect <SSID> [password <PSK>]"
  echo "    Then re-run this script."
  die "network required"
fi
echo "    cache reachable"

echo "==> Installing NixOS"
# The exact package REVISIONS are pinned by the flake.lock in the embedded
# repo, so this installs the same versions verified on tile; only the delivery
# is over the network.
nixos-install \
  --root "$MNT" \
  --flake "$MNT/etc/nixos#obsidian" \
  --no-root-password

echo "==> Post-install checks"
# The installed kernel cmdline must carry resume= or hibernation is dead on
# arrival. Check the generated boot entry rather than trusting the config.
if grep -rqs "resume=/dev/mapper/cryptswap" "$MNT/boot/loader/entries/" 2>/dev/null; then
  echo "    OK: resume=/dev/mapper/cryptswap present in boot entry"
else
  echo "    WARNING: resume= not found in $MNT/boot/loader/entries/."
  echo "             Hibernation will not resume. Verify after first boot:"
  echo "               cat /proc/cmdline | tr ' ' '\\n' | grep resume"
fi

echo "==> Setting a password for joshua"
nixos-enter --root "$MNT" -c "passwd joshua" || \
  echo "    (skipped — set it after first boot with: passwd joshua)"

cat <<'DONE'

  ============================================================
   Done. Remove the USB and reboot.

   After first boot, verify:
     cat /proc/cmdline | tr ' ' '\n' | grep resume   # resume=/dev/mapper/cryptswap
     swapon --show                                    # partition prio 0, file prio 10
     nmcli -f NAME connection show | head             # Wi-Fi profiles present
     lsusb | grep -i synaptics                        # fingerprint reader id

   Then test hibernation explicitly:
     systemctl hibernate     # power back on; session should be restored
  ============================================================
DONE
