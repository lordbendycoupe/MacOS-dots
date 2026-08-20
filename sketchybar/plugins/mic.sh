#!/usr/bin/env bash

# Live mic-in-use signal, read from the real Control Center status item's
# accessibility description (a single fast attribute read, not a full UI
# traversal, so it never blocks). This mirrors whether anything currently
# holds the mic open, which is the closest safe proxy to "muted or not"
# without needing Full Disk Access or risking a hung AX call.
DESC="$(osascript -e 'tell application "System Events" to tell process "ControlCenter" to get description of (first menu bar item of menu bar 1 whose value of attribute "AXIdentifier" is "com.apple.menuextra.controlcenter")' 2>/dev/null)"

if printf '%s' "$DESC" | grep -qi "Microphone is in use"; then
  sketchybar --set "$NAME" icon=$'' icon.color=0xff24273a label="Mic" label.color=0xff24273a background.color=0xffed8796
else
  sketchybar --set "$NAME" icon=$'' icon.color=0xffcad3f5 label="Mic" label.color=0xffcad3f5 background.color=0xff5b6078
fi
