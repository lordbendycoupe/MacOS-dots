#!/usr/bin/env bash

# Themed like the dotfiles' current_space peach dot: focused workspace gets
# a solid peach pill with a dark number; unfocused ones stay flush/dim.
PEACH=0xfff5a97f
BASE=0xff24273a
SUBTEXT=0xffa5adcb

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set "$NAME" \
    background.drawing=on \
    background.color="$PEACH" \
    label.color="$BASE" \
    label.font="JetBrainsMono Nerd Font:Bold:14.0"
else
  sketchybar --set "$NAME" \
    background.drawing=off \
    label.color="$SUBTEXT" \
    label.font="JetBrainsMono Nerd Font:Medium:14.0"
fi
