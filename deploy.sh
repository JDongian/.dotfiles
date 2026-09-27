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
#   4. git push             — only reached if everything above succeeded, so
#                             upstream only ever sees configs that deployed.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
    echo "error: must run as root (nixos-rebuild switch needs it)" >&2
    exit 1
fi

host=$(hostname)
msg=${1:-"config: deploy from $host $(date '+%Y-%m-%d %H:%M')"}

# --- 1. commit ---------------------------------------------------------------
git add -A
if git diff --cached --quiet; then
    echo ">>> nothing to commit; deploying HEAD ($(git rev-parse --short HEAD))"
else
    git commit -m "$msg"
    echo ">>> committed $(git rev-parse --short HEAD): $msg"
fi

# --- 2. sanity-check all hosts -----------------------------------------------
echo ">>> nix flake check (evaluating all hosts)..."
nix flake check

# --- 3. deploy this host -----------------------------------------------------
echo ">>> nixos-rebuild switch --flake .#$host"
nixos-rebuild switch --flake ".#$host"

# --- 4. push -----------------------------------------------------------------
echo ">>> pushing to $(git remote get-url origin)"
git push

echo ">>> deployed $(git rev-parse --short HEAD) on $host and pushed."
