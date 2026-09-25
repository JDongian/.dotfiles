#!/usr/bin/env bash
# =============================================================================
# Tailscale state for waybar (image module).
# =============================================================================
#
# ONE-SHOT, not a loop: waybar's `image` module re-execs this every `interval`
# and reads exactly two lines -- line 1 is the image path, line 2 is the
# tooltip (parsed as Pango markup, so &#10; is used for line breaks since only
# a single line is read). That contract is why this is not a custom/ module
# with JSON like netspeed.sh and diskio.sh.
#
# The icon is Tailscale's own logo, vendored from their systray client
# (client/systray/tailscale.svg, BSD-3-Clause) with the dark background rect
# stripped so it sits on the bar cleanly -- equivalent to their "dark:nobg"
# theme. The dot pattern is upstream's `connected` state.
#
# `tailscale status` is read-only and works unprivileged. It gets a hard
# timeout because the CLI blocks if tailscaled is wedged.
set -uo pipefail

ICONS="${HOME}/.config/waybar/icons"
# Upstream's two states: `connected` (middle row + bottom centre bright) and
# `disconnected` (all nine dots gray). Generated from their SVG by putting
# every dot at the same 0.4 opacity the dim dots already use.
ACTIVE="$ICONS/tailscale-active.png"
INACTIVE="$ICONS/tailscale-inactive.png"

json=$(timeout 5 tailscale status --json 2>/dev/null)

if [[ -z $json ]]; then
  printf '%s\n' "$INACTIVE"
  printf 'Tailscale: no response from tailscaled\n'
  exit 0
fi

# Delimiter is ASCII US (0x1f), NOT tab: tab counts as IFS *whitespace* and
# bash collapses runs of it, so the normally-empty exit-node fields would
# vanish and shift every later field left.
IFS=$'\037' read -r backend online ip host exit_host peers version <<<"$(
  printf '%s' "$json" | jq -r '[
    (.BackendState // "Unknown"),
    ((.Self.Online // false) | tostring),
    (.TailscaleIPs[0] // "-"),
    (.Self.HostName // "-"),
    ([.Peer[]? | select(.ExitNode == true) | .HostName] | first // ""),
    ([.Peer[]? | select(.Online == true)] | length | tostring),
    (.Version // "-")
  ] | map(tostring) | join("")' 2>/dev/null
)"

state="$backend"
[[ $backend == "Running" && $online != "true" ]] && state="Running (node offline)"

tip="${host:--} — ${state}&#10;${ip:--}&#10;${peers:-0} peers online&#10;tailscale ${version:--}"
[[ -n ${exit_host:-} ]] && tip="${tip}&#10;exit node: ${exit_host}"

if [[ $backend == "Running" && $online == "true" ]]; then
  printf '%s\n' "$ACTIVE"
else
  printf '%s\n' "$INACTIVE"
fi
printf '%s\n' "$tip"
