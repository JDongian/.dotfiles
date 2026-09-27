#!/usr/bin/env bash
# deploy.sh — commit, sanity-check, switch, push.
#
# Usage: sudo ./deploy.sh [commit message]
#
# Order of operations, and why:
#   1. git commit           — first, so the generation being deployed always
#                             corresponds to a commit (dirty-tree deploys are
#                             how "works on my machine, unreproducible" states
#                             happen). A failed deploy leaves the commit local
#                             and unpushed, which is exactly the record needed
#                             to debug or revert it.
#   2. nix flake check      — evaluates EVERY host's toplevel (tile, gravel,
#                             installer too), so a typo in shared modules is
#                             caught even when it only breaks another machine.
#                             Eval-only for other hosts; nothing is built yet.
#   3. nixos-rebuild switch — builds and activates THIS host. This is the real
#                             build test; it stops here on any failure.
#   4. hyprland refresh     — best-effort, never fails the deploy. A running
#                             Hyprland outlives the switch and keeps stale
#                             state in memory: the config symlink swap doesn't
#                             fire its file watcher, and hyprcursor caches the
#                             resolved theme path — `setcursor` with the SAME
#                             theme name is a no-op, so bounce through another
#                             theme to force a re-resolve (2026-09-27: a
#                             deployed cursor hotspot fix silently didn't
#                             apply until the compositor was poked).
#   5. git push             — only reached if everything above succeeded, so
#                             upstream only ever sees configs that deployed.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: must run as root (nixos-rebuild switch needs it)" >&2
    exit 1
fi

# Git runs as the invoking user, not root: root has no SSH key for the push,
# and root-owned files in .git break later git commands run as the user.
if [ -z "${SUDO_USER:-}" ]; then
    echo "error: run via sudo from your user, not as root directly (git needs your identity)" >&2
    exit 1
fi
as_user() { sudo -Hu "$SUDO_USER" "$@"; }

host=$(hostname)
msg=${1:-"config: deploy from $host $(date '+%Y-%m-%d %H:%M')"}

# --- 1. commit ---------------------------------------------------------------
as_user git add -A
if as_user git diff --cached --quiet; then
    echo ">>> nothing to commit; deploying HEAD ($(git rev-parse --short HEAD))"
else
    as_user git commit -m "$msg"
    echo ">>> committed $(git rev-parse --short HEAD): $msg"
fi

# --- 2. sanity-check all hosts -----------------------------------------------
echo ">>> nix flake check (evaluating all hosts)..."
nix flake check

# --- 3. deploy this host -----------------------------------------------------
echo ">>> nixos-rebuild switch --flake .#$host"
nixos-rebuild switch --flake ".#$host"

# --- 4. refresh running Hyprland session (best-effort) ------------------------
runtime_dir="/run/user/$(id -u "$SUDO_USER")"
hypr_sig=$(ls -t "$runtime_dir/hypr" 2>/dev/null | head -1 || true)
if [ -n "$hypr_sig" ]; then
    hypr() {
        sudo -u "$SUDO_USER" env XDG_RUNTIME_DIR="$runtime_dir" \
            HYPRLAND_INSTANCE_SIGNATURE="$hypr_sig" hyprctl "$@"
    }
    echo ">>> refreshing running Hyprland (config reload + cursor theme bounce)"
    hypr -q reload || true
    cursor_theme=$(grep -oP '^env = HYPRCURSOR_THEME,\K.*' dotfiles/hypr/hyprland.conf || true)
    cursor_size=$(grep -oP '^env = HYPRCURSOR_SIZE,\K.*' dotfiles/hypr/hyprland.conf || true)
    if [ -n "$cursor_theme" ] && [ -n "$cursor_size" ]; then
        hypr -q setcursor Adwaita 24 || true
        hypr -q setcursor "$cursor_theme" "$cursor_size" || true
    fi
else
    echo ">>> no running Hyprland session; skipping refresh"
fi

# --- 5. push -------------------------------------------------------------------
echo ">>> pushing to $(git remote get-url origin)"
as_user git push

echo ">>> deployed $(git rev-parse --short HEAD) on $host and pushed."
