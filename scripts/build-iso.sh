#!/usr/bin/env bash
# Build the obsidian installer ISO.
#
# WHY THIS WRAPPER EXISTS: the Wi-Fi profiles live in a gitignored directory,
# which a pure flake evaluation cannot see (twice over -- see the wifiDir
# comment in flake.nix). Including them requires --impure plus an env var.
# Running `nix build .#installer` by hand still works but SILENTLY produces an
# ISO with no saved networks, so use this script and read what it prints.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

WIFI_DIR="$REPO/wifi-secrets"
ARGS=(build .#installer --print-out-paths)

if [ -d "$WIFI_DIR" ] && compgen -G "$WIFI_DIR/*.nmconnection" >/dev/null; then
  n=$(find "$WIFI_DIR" -name '*.nmconnection' | wc -l)
  echo "Wi-Fi: embedding $n profile(s) from $WIFI_DIR"
  echo "       ==> the resulting ISO WILL CONTAIN PLAINTEXT PASSWORDS."
  export OBSIDIAN_WIFI_DIR="$WIFI_DIR"
  ARGS+=(--impure)
else
  echo "Wi-Fi: none staged — ISO will contain NO saved networks."
  echo "       Run scripts/stage-wifi.sh first if you want them."
fi

echo "Building (this takes a while; the full obsidian closure is embedded)..."
out=$(nix "${ARGS[@]}")
iso=$(find "$out/iso" -name '*.iso' | head -1)

echo
echo "ISO:  $iso"
echo "Size: $(du -h "$iso" | cut -f1)"
echo
echo "Write it to a USB with (VERIFY THE DEVICE FIRST -- this destroys it):"
echo "  sudo dd if=$iso of=/dev/sdX bs=4M status=progress oflag=sync"
