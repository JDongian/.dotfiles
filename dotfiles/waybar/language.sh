#!/usr/bin/env bash
# =============================================================================
# Keyboard layout indicator for waybar (custom/language).
# =============================================================================
#
# WHY NOT the built-in hyprland/language module: it has no tooltip support at
# all. Its module never calls set_tooltip, and ALabel -- which it inherits --
# contains no tooltip machinery either, so `tooltip-format` on it is silently
# ignored. Showing the switch hotkey on hover therefore needs a custom module.
#
# EVENT-DRIVEN, not polled: subscribes to Hyprland's event socket (.socket2)
# and re-reads only when an `activelayout` event fires, so switching layouts
# updates the bar instantly and an idle machine costs nothing. Falls back to a
# slow poll if the socket is unavailable, so the module can never go stale.
set -uo pipefail

# No icon: the Nerd Font keyboard codepoint rendered as a stray triangle here,
# and "DV" / "US" is self-explanatory without one.

# Kept in sync with hyprland.conf's bind by hand -- there is no way to query a
# bind for a given dispatcher, so if that keybind moves, change it here too.
HOTKEY="Super+Shift+Space"

sock="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# Last payload emitted, so repeats can be dropped -- see the loop below.
last=""

emit() {
  # The `main` keyboard is the built-in one; this laptop enumerates seven
  # keyboard devices and they all carry the same layout, so read just the one.
  local km short cls out
  km=$(hyprctl devices -j 2>/dev/null |
    jq -r '[.keyboards[]? | select(.main == true) | .active_keymap] | first // empty' 2>/dev/null)
  [[ -z $km ]] && km=$(hyprctl devices -j 2>/dev/null |
    jq -r '[.keyboards[]?.active_keymap] | first // empty' 2>/dev/null)
  [[ -z $km ]] && km="unknown"

  case "$km" in
    *Dvorak*) short="DV"; cls="dvorak" ;;
    *"(US)"*) short="US"; cls="us" ;;
    unknown)  short="??"; cls="error" ;;
    # Anything else: first two letters, uppercased, so a third layout added
    # later still renders something sane instead of blank.
    *)        short=$(printf '%.2s' "$km" | tr '[:lower:]' '[:upper:]'); cls="other" ;;
  esac

  printf -v out '{"text":"%s","tooltip":"%s\\n%s to switch","class":"%s"}' \
    "$short" "$km" "$HOTKEY" "$cls"

  # Hyprland emits one activelayout event PER KEYBOARD DEVICE, and this laptop
  # has seven, so a single toggle fires seven identical updates. Drop repeats
  # rather than re-spawning hyprctl+jq and re-rendering the bar seven times.
  [[ $out == "$last" ]] && return
  last=$out
  printf '%s\n' "$out"
}

emit

if [[ -S $sock ]]; then
  # ncat speaks UNIX sockets with -U. Hyprland emits lines like
  # "activelayout>>at-translated-set-2-keyboard,English (Dvorak)".
  while IFS= read -r line; do
    case "$line" in
      activelayout*) emit ;;
    esac
  done < <(ncat -U "$sock" 2>/dev/null)
fi

# Reached only if the socket is missing or the subscription ended. Poll slowly
# rather than exiting, so a lost subscription degrades instead of going blank.
while :; do
  sleep 5
  emit
done
