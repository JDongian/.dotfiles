#!/usr/bin/env bash
# =============================================================================
# Disk IOPS for waybar (custom/diskio).
# =============================================================================
#
# REPLACES the old `iostat -dx | awk '/^sda/ {print $4 "/" $5}'` module, which
# was broken two independent ways and had never worked on this host:
#   1. the `iostat` on PATH is BusyBox's, which has no -x flag -- every run
#      exited with "invalid option -- 'x'" and a usage dump, once every 5s;
#   2. it grepped ^sda on a machine whose only disk is nvme0n1, so even with
#      sysstat installed the pattern would never have matched.
#
# Reads /proc/diskstats directly instead: no sysstat dependency and no parsing
# of a human-facing table that changes shape between implementations. Per
# Documentation/admin-guide/iostats.rst the fields are
#   $1 major  $2 minor  $3 name
#   $4 reads completed   $6 sectors read
#   $8 writes completed  $10 sectors written
# Sectors are always 512 bytes here regardless of physical block size.
#
# Continuous module, same shape as netspeed.sh: loops, prints one JSON line per
# tick, diffs counters in-process so there is no state file.
set -uo pipefail

interval="${1:-5}"

# Resolve the physical disk backing / rather than hardcoding a name. This
# config is shared with tile and gravel, and / here is a LUKS mapper device
# (/dev/mapper/cryptroot) whose parent chain has to be walked to reach the
# real disk -- `lsblk -nso` prints that chain child-first, so the last line is
# the whole disk. Falls back to the first disk-type device if that fails.
# -l (list) not the default tree output: `lsblk -nso` draws box-drawing
# characters ("\u2514\u2500nvme0n1") that end up in the device name.
disk=$(lsblk -nslo NAME "$(findmnt -no SOURCE / 2>/dev/null)" 2>/dev/null | tail -1 | tr -d ' ')
[[ -z $disk ]] && disk=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1; exit}')

# Same 4-column-max formatter netspeed.sh uses, so the two modules line up.
# SI prefix only; callers append any unit themselves.
fmt() {
  awk -v v="$1" 'BEGIN {
    u[1] = ""; u[2] = "k"; u[3] = "M"; u[4] = "G"; u[5] = "T"
    i = 1
    while (v >= 1000 && i < 5) { v /= 1000; i++ }
    if (i == 1) { printf "%.0f", v; exit }
    s = sprintf("%.1f", v)
    if (s + 0 < 10) printf "%s%s", s, u[i]
    else            printf "%.0f%s", v, u[i]
  }'
}

prev_r=0
prev_w=0
prev_sr=0
prev_sw=0
primed=0

while :; do
  stats=$(awk -v d="$disk" '$3 == d { print $4, $8, $6, $10; exit }' /proc/diskstats)

  if [[ -z $stats ]]; then
    printf '{"text":"󰋊  n/a","tooltip":"No diskstats for %s","class":"error"}\n' "$disk"
    sleep "$interval"
    continue
  fi

  read -r r w sr sw <<<"$stats"

  if (( primed == 0 )); then
    # First tick has nothing to diff against; report idle rather than the
    # since-boot totals, which would render as a meaningless huge spike.
    primed=1
    prev_r=$r; prev_w=$w; prev_sr=$sr; prev_sw=$sw
  fi

  dr=$(( r  - prev_r  )); (( dr < 0 )) && dr=0
  dw=$(( w  - prev_w  )); (( dw < 0 )) && dw=0
  dsr=$(( sr - prev_sr )); (( dsr < 0 )) && dsr=0
  dsw=$(( sw - prev_sw )); (( dsw < 0 )) && dsw=0
  prev_r=$r; prev_w=$w; prev_sr=$sr; prev_sw=$sw

  riops=$(( dr / interval ))
  wiops=$(( dw / interval ))
  rbps=$(( dsr * 512 / interval ))
  wbps=$(( dsw * 512 / interval ))

  tooltip=$(printf '%s\\nread   %s IOPS   %sB/s\\nwrite  %s IOPS   %sB/s\\ntotal  %s reads   %s writes' \
    "$disk" \
    "$(fmt "$riops")" "$(fmt "$rbps")" \
    "$(fmt "$wiops")" "$(fmt "$wbps")" \
    "$(fmt "$r")" "$(fmt "$w")")

  # No manual padding -- %-4s left-aligned the write figure and left trailing
  # spaces, which read as a gap between this module and its neighbour. Width
  # stability comes from "min-length" on the module instead.
  printf '{"text":"󰋊 %s/%s","tooltip":"%s","class":"ok"}\n' \
    "$(fmt "$riops")" "$(fmt "$wiops")" "$tooltip"

  sleep "$interval"
done
