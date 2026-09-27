#!/usr/bin/env bash
# Change screen brightness, then show/update a dunst OSD with the new % — the
# brightness counterpart to pasystray's volume popups (brightnessctl is silent).
# $1 goes to `brightnessctl set` (e.g. "5%+", "10%-").
#
# Plain x-dunst-stack-tag: dunst replaces the brightness popup by tag, no id
# file needed. (The earlier "decreases don't update" turned out to be an
# unwired scroll-down binding, not a dunst issue, so no replaces-id workaround
# is warranted.)
set -eu
brightnessctl -q set "$1"
pct=$(brightnessctl -m | awk -F, 'NR==1 {gsub("%","",$4); print $4}')
notify-send -a brightness \
  -h "string:x-dunst-stack-tag:brightness" \
  -h "int:value:$pct" \
  "Brightness ${pct}%"
