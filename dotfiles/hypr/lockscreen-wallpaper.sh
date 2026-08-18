#!/usr/bin/env bash
# Pick the Lake Tahoe lock-screen wallpaper matching the current time of day.
#
# hyprlock's `background { path = }` is a STATIC hyprlang string — unlike the
# label widgets it does NOT support `cmd[]` substitution, so the variant cannot
# be chosen from inside hyprlock.conf. Instead hyprlock.conf points at a fixed
# symlink and this script repoints that symlink just before the locker starts.
#
# Invoked from hyprlock.service's ExecStartPre (see home.nix), which is the one
# choke point every lock path funnels through: hypridle's 300s timeout,
# before_sleep_cmd on suspend, and any manual `loginctl lock-session`. That
# means the wallpaper is also re-evaluated on resume-from-sleep, so a machine
# suspended at noon and opened at midnight unlocks to the night variant.
#
# The symlink is swapped atomically (ln -sfn to a temp name + mv -T) so a locker
# starting concurrently can never observe a missing target and fall back to a
# black background.

set -euo pipefail

# The image directory is a home-manager symlink into the read-only Nix store,
# so the `current.jpg` link CANNOT live inside it (mv would fail EROFS). It
# goes one level up, in a plain writable directory that home-manager does not
# manage. Keep these two paths distinct.
data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
wallpaper_dir="$data_dir/tahoe"
link="$data_dir/tahoe-current.jpg"

hour=$(date +%-H)

# Four variants of the same shoreline, ordered by how the light actually reads
# in each image rather than by clock-astronomy:
#   morning  05-10  pink dawn sky
#   day      10-17  bright midday, blue sky and turquoise water
#   evening  17-21  overcast blue dusk
#   night    21-05  starfield
if   [ "$hour" -ge 5 ]  && [ "$hour" -lt 10 ]; then variant=morning
elif [ "$hour" -ge 10 ] && [ "$hour" -lt 17 ]; then variant=day
elif [ "$hour" -ge 17 ] && [ "$hour" -lt 21 ]; then variant=evening
else                                                variant=night
fi

target="$wallpaper_dir/$variant.jpg"

# If the expected image is missing, leave whatever the link currently points at
# alone rather than breaking the lock screen.
[ -e "$target" ] || exit 0

mkdir -p "$data_dir"

ln -sfn "$target" "$link.tmp"
mv -Tf "$link.tmp" "$link"
