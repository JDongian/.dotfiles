#!/usr/bin/env bash
# Stage this machine's saved Wi-Fi profiles for baking into the obsidian
# installer ISO.
#
# SECURITY: .nmconnection files contain PLAINTEXT pre-shared keys. The
# destination (wifi-secrets/) is gitignored and must STAY gitignored -- this
# repo is published to github.com/JDongian/.dotfiles. This script refuses to
# run if that ignore rule is missing, so a future .gitignore edit cannot
# silently turn a build into a credential leak.
#
# INTERFACE PINNING: NetworkManager records `interface-name=wlp0s20f3` (tile's
# NIC) in each profile. On obsidian the wireless interface may enumerate under
# a different name, and a profile pinned to a non-existent interface simply
# never matches -- you would see the SSID but never auto-connect. We strip that
# line so profiles bind by SSID on whatever interface exists.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="/etc/NetworkManager/system-connections"
DEST="$REPO/wifi-secrets"

if ! git -C "$REPO" check-ignore -q "$DEST/probe.nmconnection"; then
  echo "REFUSING: $DEST is not gitignored. Add 'wifi-secrets/' to .gitignore." >&2
  exit 1
fi

[ -d "$SRC" ] || { echo "No NetworkManager profiles at $SRC" >&2; exit 1; }

# Recreate cleanly so removed networks do not linger from an earlier staging.
rm -rf "$DEST"
mkdir -p "$DEST"
chmod 700 "$DEST"

count=0
shopt -s nullglob
for f in "$SRC"/*.nmconnection; do
  base="$(basename "$f")"
  # Drop the interface pin; keep everything else byte-for-byte.
  sed '/^interface-name=/d' "$f" > "$DEST/$base"
  chmod 600 "$DEST/$base"
  count=$((count + 1))
done

echo "Staged $count Wi-Fi profile(s) into $DEST (gitignored, mode 0600)."
echo "Reminder: the resulting ISO carries these secrets in cleartext."
