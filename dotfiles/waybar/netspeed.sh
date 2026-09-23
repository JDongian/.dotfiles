#!/usr/bin/env bash
# =============================================================================
# Condensed up/down network throughput for waybar (custom/netspeed).
# =============================================================================
#
# WHY A SCRIPT AND NOT waybar's BUILT-IN `network` MODULE
# -------------------------------------------------------
# The network module CAN report throughput -- {bandwidthUpBytes},
# {bandwidthDownBytes}, {bandwidthUpBits}, etc. But its formatter bakes the
# unit into the output: include/util/format.hpp renders "{:.1f}" + SI prefix +
# a hardcoded unit string ("B/s"), and the ONLY format specs it honours are
# '>', '<' and '='. A width like {:>9} is parsed and then deliberately
# ignored ("we ignore it for now, but keep it for compatibility"). So the
# shortest that module can render both directions is roughly
#   "10.7MB/s  154.2kB/s"  -- ~19 columns.
# This prints "10.7M 154k" instead, ~11 columns, with the full detail moved
# to the tooltip.
#
# CONTINUOUS MODULE
# -----------------
# Loops forever and emits one JSON line per tick. Because the process stays
# alive it can diff the kernel's byte counters against the previous tick
# without a state file on disk. waybar treats a script with no "interval" as
# self-looping and reads a line at a time; "restart-interval" in the config
# relaunches this if it ever exits.
set -uo pipefail

interval="${1:-2}"

prev_if=""
prev_rx=0
prev_tx=0

# SI prefix only, no unit -- callers append "B/s" etc. where they want it, so
# the bar can stay bare ("154k") while the tooltip spells it out ("154kB/s").
#
# At most 4 columns so the bar never jitters: "999", "9.9k", "154k", "1.2M".
# The one-decimal branch is chosen AFTER rounding, not before: 9.96M rounds to
# "10.0" under %.1f, which is 5 columns and would shove the bar sideways, so
# that case has to fall through to the no-decimal branch and print "10M".
fmt() {
  awk -v v="$1" 'BEGIN {
    split(" k M G T", u, " ")
    # split() on a leading space still yields u[1]="k"; set the base unit
    # explicitly instead of relying on that.
    u[1] = ""; u[2] = "k"; u[3] = "M"; u[4] = "G"; u[5] = "T"
    i = 1
    while (v >= 1000 && i < 5) { v /= 1000; i++ }
    if (i == 1) { printf "%.0f", v; exit }
    s = sprintf("%.1f", v)
    if (s + 0 < 10) printf "%s%s", s, u[i]
    else            printf "%.0f%s", v, u[i]
  }'
}

while :; do
  # Follow whichever interface currently owns the default route instead of
  # pinning a name. The name differs per host (wlp0s20f3 on obsidian) and
  # changes when you move between wifi and a dock's ethernet. Taking the
  # first line picks the lowest-metric default, so a tailscale0 route added
  # as an exit node does not steal the reading.
  iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')

  if [[ -z $iface || ! -r /sys/class/net/$iface/statistics/rx_bytes ]]; then
    printf '{"text":"↓  -- ↑  --","tooltip":"No default route","class":"disconnected"}\n'
    prev_if=""
    sleep "$interval"
    continue
  fi

  read -r rx < "/sys/class/net/$iface/statistics/rx_bytes"
  read -r tx < "/sys/class/net/$iface/statistics/tx_bytes"

  if [[ $iface != "$prev_if" ]]; then
    # First sample on a new interface: no previous counter to diff against,
    # so report idle for one tick rather than a bogus spike.
    prev_if=$iface
    prev_rx=$rx
    prev_tx=$tx
  fi

  # Counters are per-interface and reset when the link is recreated; clamp
  # negatives to 0 so a reset shows as idle instead of a huge negative rate.
  drx=$(( rx - prev_rx )); (( drx < 0 )) && drx=0
  dtx=$(( tx - prev_tx )); (( dtx < 0 )) && dtx=0
  prev_rx=$rx
  prev_tx=$tx

  down_rate=$(( drx / interval ))
  up_rate=$(( dtx / interval ))

  down=$(fmt "$down_rate")
  up=$(fmt "$up_rate")

  ipaddr=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4; exit}')
  [[ -z $ipaddr ]] && ipaddr="no IPv4"

  tooltip=$(printf '%s (%s)\\ndown  %sB/s   %sb/s\\nup    %sB/s   %sb/s\\ntotal down %sB   up %sB' \
    "$iface" "$ipaddr" \
    "$(fmt "$down_rate")" "$(fmt $(( down_rate * 8 )))" \
    "$(fmt "$up_rate")"   "$(fmt $(( up_rate * 8 )))" \
    "$(fmt "$rx")" "$(fmt "$tx")")

  # %4s pads each figure to the 4-column max above, so the modules to the
  # left of this one hold still as the rate changes width.
  printf '{"text":"↓%4s ↑%4s","tooltip":"%s","class":"connected"}\n' \
    "$down" "$up" "$tooltip"

  sleep "$interval"
done
