#!/usr/bin/env bash
# JankyBorders has no built-in per-window/random color -- active_color is one
# global value applied to whatever's currently focused (see `man borders`).
# It DOES let a running instance be live-updated by just invoking
# `borders active_color=...` again, though, so this polls AeroSpace for the
# focused window id (same polling approach AutoRaise itself uses for mouse
# position, just aimed at window focus instead) and pushes a freshly-picked
# color from the Catppuccin Macchiato accents every time the focused window
# changes -- the same 7 colors already used for the sketchybar accents/icon
# theming (see sketchybar/sketchybarrc, icons/colors.conf), so it's varied
# but still matches the rest of the theme instead of raw random RGB.
set -uo pipefail

COLORS=(
  0xffc6a0f6 # mauve
  0xffed8796 # red
  0xfff5a97f # peach
  0xffeed49f # yellow
  0xffa6da95 # green
  0xff91d7e3 # sky
  0xff8aadf4 # blue
)

last_id=""
while true; do
  id=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null)
  if [[ -n "$id" && "$id" != "$last_id" ]]; then
    last_id="$id"
    color="${COLORS[RANDOM % ${#COLORS[@]}]}"
    borders active_color="$color" 2>/dev/null
  fi
  sleep 0.15
done
