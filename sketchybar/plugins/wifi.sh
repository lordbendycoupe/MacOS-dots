#!/usr/bin/env zsh

# Icon-only: off/disconnected state vs. 4-bar signal strength when
# connected. Codepoints confirmed directly against the installed
# JetBrainsMono Nerd Font's cmap (md-wifi_strength_1..4 / _off).
#
# Reads the real Control Center Wi-Fi status item's accessibility
# description as the source of truth ("Wi-Fi, connected, N bars") --
# `networksetup -getairportnetwork` was found to be unreliable on this
# machine, reporting "not associated" even while actually connected.
ICON_OFF=$'\xf3\xb0\xa4\xad'
ICON_1=$'\xf3\xb0\xa4\x9f'
ICON_2=$'\xf3\xb0\xa4\xa2'
ICON_3=$'\xf3\xb0\xa4\xa5'
ICON_4=$'\xf3\xb0\xa4\xa8'

GRAY=0xffcad3f5
SKY=0xff91d7e3
BASE=0xff24273a
OFF_BG=0xff5b6078

DESC="$(osascript -e 'tell application "System Events" to tell process "ControlCenter" to get description of (first menu bar item of menu bar 1 whose description contains "Wi")' 2>/dev/null)"

if [[ "$DESC" != *connected* ]]; then
  sketchybar --set "$NAME" icon="$ICON_OFF" icon.color="$GRAY" background.color="$OFF_BG"
  exit 0
fi

BARS="$(echo "$DESC" | grep -oE '[0-9]+ bar' | grep -oE '[0-9]+')"

case "$BARS" in
  1) ICON="$ICON_1" ;;
  2) ICON="$ICON_2" ;;
  3) ICON="$ICON_3" ;;
  4) ICON="$ICON_4" ;;
  *) ICON="$ICON_4" ;;
esac

sketchybar --set "$NAME" icon="$ICON" icon.color="$BASE" background.color="$SKY"
