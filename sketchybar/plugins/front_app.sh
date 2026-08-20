#!/usr/bin/env zsh

# Icon mapping: base set carried over from dotfiles, expanded to cover the
# apps actually installed on this machine (see /Applications). Every glyph
# is set via an explicit \u/\U escape rather than a pasted character --
# pasted BMP-range Nerd Font glyphs were silently getting stripped to empty
# when written to disk in this environment, while escape sequences don't
# have that problem.
ICON_PADDING_RIGHT=5
TEXT=0xffcad3f5
GREEN=0xffa6da95

# Retro 8-bit pixel-art icons (generated from each app's real icon) live
# here, one PNG per app, filename = app name with spaces -> underscores.
# sketchybar has no standalone "image" element in this build -- images can
# only be drawn via a domain's background.image, so the glyph slot is
# blanked out (icon=" ") and icon.background carries the picture instead.
ICON_DIR="$HOME/.config/sketchybar/icons"
SLUG="${INFO// /_}"
PIXEL_ICON="$ICON_DIR/$SLUG.png"
COLOR_FILE="$ICON_DIR/colors.conf"

if [[ -f "$PIXEL_ICON" ]]; then
  # Uniform accent across icon/name/group: same color the icon's own
  # backdrop was generated with, looked up by slug. Falls back to the
  # default green if this particular icon predates colors.conf.
  ACCENT=$(awk -F= -v k="$SLUG" '$1==k{print $2}' "$COLOR_FILE" 2>/dev/null)
  [[ -z "$ACCENT" ]] && ACCENT="$GREEN"

  sketchybar --set $NAME icon.drawing=on \
                         icon=" " \
                         icon.color=0x00ffffff \
                         icon.width=22 \
                         icon.padding_left=8 \
                         icon.padding_right=5 \
                         icon.background.drawing=on \
                         icon.background.color="$ACCENT" \
                         icon.background.height=20 \
                         icon.background.corner_radius=4 \
                         icon.background.image="$PIXEL_ICON" \
                         icon.background.image.scale=0.08 \
                         background.color="$ACCENT"
  sketchybar --set $NAME.name label="$INFO" background.color="$ACCENT"
  sketchybar --set front_app.group background.color="$ACCENT"
  exit 0
fi

case $INFO in
"Arc") ICON_PADDING_RIGHT=5; ICON=$'\xf3\xb0\x9e\x8d' ;;
"Code"|"Visual Studio Code") ICON_PADDING_RIGHT=4; ICON=$'\xf3\xb0\xa8\x9e' ;;
"VSCodium") ICON_PADDING_RIGHT=4; ICON=$'\xf3\xb0\xa8\x9e' ;;
"Calendar") ICON_PADDING_RIGHT=3; ICON=$'' ;;
"Discord") ICON=$'' ;;
"FaceTime") ICON_PADDING_RIGHT=5; ICON=$'' ;;
"Finder") ICON=$'\xf3\xb0\x80\xb6' ;;
"Google Chrome") ICON_PADDING_RIGHT=7; ICON=$'' ;;
"IINA") ICON_PADDING_RIGHT=4; ICON=$'\xf3\xb0\x95\xbc' ;;
"kitty") ICON=$'\xf3\xb0\x84\x9b' ;;
"Alacritty") ICON=$'\xf3\xb0\x84\x9b' ;;
"iTerm2") ICON=$'\xf3\xb0\x84\x9b' ;;
"Messages") ICON=$'' ;;
"Notion") ICON_PADDING_RIGHT=6; ICON=$'\xf3\xb0\x8e\x9a' ;;
"Preview") ICON_PADDING_RIGHT=3; ICON=$'' ;;
"Slack") ICON=$'' ;;
"Spotify") ICON_PADDING_RIGHT=2; ICON=$'' ;;
"TextEdit") ICON_PADDING_RIGHT=4; ICON=$'' ;;
"Transmission") ICON_PADDING_RIGHT=3; ICON=$'\xf3\xb0\xb6\x98' ;;
"Safari") ICON=$'' ;;
"System Settings") ICON=$'' ;;
"Mail") ICON=$'' ;;
"Notes") ICON=$'\xf3\xb0\xa0\xae' ;;
"Terminal") ICON=$'\xf3\xb0\x86\x8d' ;;
"AeroSpace") ICON=$'\xf3\xb0\x96\xb2' ;;
"AFFiNE") ICON=$'\xf3\xb0\x88\x9a' ;;
"Caffeine") ICON=$'' ;;
"Claude") ICON=$'\xf3\xb0\xa7\x91' ;;
"Docker") ICON=$'\xf3\xb0\xa1\xa8' ;;
"GarageBand") ICON=$'' ;;
"Image2Icon") ICON=$'\xf3\xb0\x8b\xa9' ;;
"iMovie") ICON=$'' ;;
"IntelliJ IDEA") ICON=$'' ;;
"Keynote") ICON=$'\xf3\xb0\x90\xa1' ;;
"Numbers") ICON=$'\xf3\xb0\x8e\x9a' ;;
"Obsidian") ICON=$'\xf3\xb1\x93\xa7' ;;
"Opera") ICON=$'' ;;
"Pages") ICON=$'' ;;
"ProtonVPN") ICON=$'\xf3\xb0\xa6\x9d' ;;
"Raycast") ICON=$'' ;;
"Rectangle") ICON=$'\xf3\xb0\x96\xb2' ;;
"Safe Exam Browser") ICON=$'\xf3\xb0\x8c\xbe' ;;
"Sound Control") ICON=$'\xf3\xb0\x95\xbe' ;;
"Steam") ICON=$'' ;;
"Upscayl") ICON=$'\xf3\xb0\x8b\xa9' ;;
"Xcode") ICON=$'\xf3\xb0\xbd\x98' ;;
*) ICON_PADDING_RIGHT=2; ICON=$'' ;;
esac

sketchybar --set $NAME icon.background.drawing=off \
                       icon.width=0 \
                       icon.color="$TEXT" \
                       icon=$ICON \
                       icon.padding_left=9 \
                       icon.padding_right=$ICON_PADDING_RIGHT \
                       background.color="$GREEN"
sketchybar --set $NAME.name label="$INFO" background.color="$GREEN"
sketchybar --set front_app.group background.color="$GREEN"
