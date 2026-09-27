#!/usr/bin/env bash
# =============================================================================
# Combined filesystem view for waybar (custom/diskio): "21% 0/3"
#   21%  = usage of /            (df)
#   0/3  = read / write IOPS     (/proc/diskstats delta over the interval)
# The separate `disk` usage module and its icon are folded in here.
#
# BACKGROUND encodes I/O activity (text stays white): reads push toward cyan
# (0,255,255), writes toward red (255,0,0), each mapped through a logistic
# sigmoid of the IOPS rate so idle is black and bursts saturate. The colour is
# picked from a CSS grid (#custom-diskio.rd<R>wr<W>) since waybar can only take
# a class, not an inline colour.
#
# /proc/diskstats fields (admin-guide/iostats.rst):
#   $3 name  $4 reads completed  $6 sectors read  $8 writes completed
# Sectors are 512 bytes.
set -uo pipefail

interval="${1:-5}"

# Sigmoid coefficients: MID is the IOPS at 50% intensity, WIDTH the softness.
# Tuned for an NVMe desktop: idle (~0) -> ~black, light activity mid, bursts
# saturate. Bump MID if the cell reads too hot at light load.
SIG_MID=170
SIG_WIDTH=48

# Resolve the physical disk backing / (LUKS mapper -> walk to the whole disk).
disk=$(lsblk -nslo NAME "$(findmnt -no SOURCE / 2>/dev/null)" 2>/dev/null | tail -1 | tr -d ' ')
[[ -z $disk ]] && disk=$(lsblk -dno NAME,TYPE 2>/dev/null | awk '$2=="disk"{print $1; exit}')

fmt() { # compact SI, max 4 cols
  awk -v v="$1" 'BEGIN {
    u[1]=""; u[2]="k"; u[3]="M"; u[4]="G"; u[5]="T"; i=1
    while (v >= 1000 && i < 5) { v /= 1000; i++ }
    if (i == 1) { printf "%.0f", v; exit }
    s = sprintf("%.1f", v)
    if (s + 0 < 10) printf "%s%s", s, u[i]; else printf "%.0f%s", v, u[i]
  }'
}

# IOPS rate -> 0..100 intensity bucket (nearest ten) via a logistic sigmoid.
hfmt() { # bytes -> human (1024)
  awk -v x="$1" 'BEGIN { u[0]="B";u[1]="K";u[2]="M";u[3]="G";u[4]="T"; i=0
    while (x>=1024 && i<4){ x/=1024; i++ }
    if (i==0) printf "%d%s", x, u[i]; else printf "%.1f%s", x, u[i] }'
}

intensity_bucket() {
  awk -v x="$1" -v m="$SIG_MID" -v w="$SIG_WIDTH" 'BEGIN {
    if (x < 5) { print 0; exit }
    i = 100 / (1 + exp(-(x - m) / w))
    b = int((i + 5) / 10) * 10
    if (b > 100) b = 100
    if (b < 0) b = 0
    print b
  }'
}

prev_r=0; prev_w=0; prev_sr=0; prev_sw=0; primed=0

while :; do
  stats=$(awk -v d="$disk" '$3 == d { print $4, $8, $6, $10; exit }' /proc/diskstats)
  # stat -f = statvfs(/) only; never scans other mounts, so a dead /mnt/tile
  # sshfs cannot hang it the way `df` (which walks the whole mount table) does.
  read -r bs bt bf ba <<<"$(stat -f -c '%S %b %f %a' / 2>/dev/null || echo 0 0 0 0)"
  usage=$(awk -v b="$bt" -v f="$bf" -v a="$ba" 'BEGIN{ u=b-f; d=u+a; printf "%.0f",(d>0?u/d*100:0) }')
  [[ -z $usage ]] && usage=0
  used_h=$(hfmt $(( bs*(bt-bf) ))); total_h=$(hfmt $(( bs*bt ))); free_h=$(hfmt $(( bs*ba )))

  if [[ -z $stats ]]; then
    printf '{"text":"󰋊 %s%% n/a","tooltip":"No diskstats for %s","class":"rd0wr0"}\n' "$usage" "$disk"
    sleep "$interval"; continue
  fi

  read -r r w sr sw <<<"$stats"
  if (( primed == 0 )); then primed=1; prev_r=$r; prev_w=$w; prev_sr=$sr; prev_sw=$sw; fi

  dr=$(( r - prev_r ));   (( dr < 0 )) && dr=0
  dw=$(( w - prev_w ));   (( dw < 0 )) && dw=0
  dsr=$(( sr - prev_sr )); (( dsr < 0 )) && dsr=0
  dsw=$(( sw - prev_sw )); (( dsw < 0 )) && dsw=0
  prev_r=$r; prev_w=$w; prev_sr=$sr; prev_sw=$sw

  riops=$(( dr / interval ))
  wiops=$(( dw / interval ))
  rbps=$(( dsr * 512 / interval ))
  wbps=$(( dsw * 512 / interval ))

  rb=$(intensity_bucket "$riops")   # reads  -> cyan (green+blue)
  wb=$(intensity_bucket "$wiops")   # writes -> red

  tooltip=$(printf 'Filesystem %s  •  %s%% used\\n%s of %s   (%s free)\\nread   %s IOPS   %sB/s\\nwrite  %s IOPS   %sB/s' \
    "$disk" "$usage" "$used_h" "$total_h" "$free_h" \
    "$(fmt "$riops")" "$(fmt "$rbps")" \
    "$(fmt "$wiops")" "$(fmt "$wbps")")

  printf '{"text":"󰋊 %s%% %s/%s","tooltip":"%s","class":"rd%swr%s"}\n' \
    "$usage" "$(fmt "$riops")" "$(fmt "$wiops")" "$tooltip" "$rb" "$wb"

  sleep "$interval"
done
