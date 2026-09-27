#!/usr/bin/env bash
# RAM module that also encodes swap in its BACKGROUND (the old custom/swap
# indicator is folded in here). Emits waybar JSON: text = RAM used %, plus a
# class the CSS turns into a background:
#   - no swap in use  -> grayscale by RAM%   (r20..r100, black -> white, like CPU)
#   - any swap in use -> yellow -> red by swap% (sw20..sw100): yellow the instant
#                        swapping starts, red at 100% swap used.
set -eu

vals=$(free -m | awk '
  /^Mem:/  { rt=$2; ru=$3 }
  /^Swap:/ { st=$2; su=$3 }
  END { printf "%.0f %.0f", (rt>0 ? ru/rt*100 : 0), (st>0 ? su/st*100 : 0) }')
ram=${vals% *}
swap=${vals#* }

bucket() { # value -> nearest ten (0..100)
  b=$(( ( $1 + 5 ) / 10 * 10 ))
  [ "$b" -gt 100 ] && b=100
  echo "$b"
}

# Background = rgb(red from swap, green from RAM, 0): more RAM -> greener, any
# swap adds red (both maxed -> yellow). CSS grid #custom-ram.g<G>r<R>.
g=$(bucket "$ram")
r=$(bucket "$swap")
cls="g${g}r${r}"
if [ "$swap" -gt 0 ]; then
  tip="RAM ${ram}%  •  SWAPPING — ${swap}% of swap in use"
else
  tip="RAM ${ram}%  •  no swap in use"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$ram" "$tip" "$cls"
