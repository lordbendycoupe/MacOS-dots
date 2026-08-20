#!/usr/bin/env bash

# Catppuccin Macchiato tiers -- both the icon (full/high/mid/low/empty) and
# the box color shift with charge level, plus a distinct charging icon+color.
# Icons are set via explicit \u escapes (not pasted glyphs) since pasted
# Nerd Font characters have silently failed to survive being written here.
PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

ICON_FULL=$''
ICON_75=$''
ICON_50=$''
ICON_25=$''
ICON_EMPTY=$''
ICON_BOLT=$''

case "${PERCENTAGE}" in
  [8-9][0-9]|100) ICON="$ICON_FULL" BOX=0xffa6da95 ;;
  7[0-9]) ICON="$ICON_75" BOX=0xffeed49f ;;
  [4-6][0-9]) ICON="$ICON_50" BOX=0xfff5a97f ;;
  [1-3][0-9]) ICON="$ICON_25" BOX=0xffee99a0 ;;
  *) ICON="$ICON_EMPTY" BOX=0xffed8796 ;;
esac

if [ "$CHARGING" != "" ]; then
  ICON="$ICON_BOLT"
  BOX=0xff8aadf4
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" icon.color=0xff24273a label="${PERCENTAGE}%" label.color=0xff24273a background.color="$BOX"
