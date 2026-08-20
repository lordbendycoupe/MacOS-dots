#!/bin/sh

# AppleCameraInterface only gets mapped into a client process (FaceTime,
# Discord, Camo, etc.) while it holds the camera stream open, unlike the
# persistent system daemons (VDCAssistant, cameracaptured), so this is a
# reliable live/idle signal. Mirrors the real macOS green camera-in-use dot;
# click_script (set in sketchybarrc) opens the actual native camera/mic
# controls dropdown.
if lsof 2>/dev/null | grep -q "AppleCameraInterface"; then
  sketchybar --set "$NAME" drawing=on icon.color=0xff24273a background.color=0xffa6da95
else
  sketchybar --set "$NAME" drawing=off
fi
