#!/usr/bin/env bash

# Reading the active Focus/DND mode requires Full Disk Access (macOS blocks
# ~/Library/DoNotDisturb/DB even from the file's owner otherwise). If that
# hasn't been granted to sketchybar, fail closed and just stay hidden rather
# than show broken data.
ASSERTIONS="$HOME/Library/DoNotDisturb/DB/Assertions.json"

if [ ! -r "$ASSERTIONS" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

MODE="$(plutil -extract data.0.storeAssertionRecords.0.assertionDetails.assertionDetailsModeIdentifier raw -o - "$ASSERTIONS" 2>/dev/null)"

if [ -z "$MODE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

case "$MODE" in
  *sleep*) LABEL="Sleep" ;;
  *work*) LABEL="Work" ;;
  *personal*) LABEL="Personal" ;;
  *driving*) LABEL="Driving" ;;
  *) LABEL="Focus" ;;
esac

sketchybar --set "$NAME" drawing=on icon=$'' icon.color=0xff24273a label="$LABEL" label.color=0xff24273a background.color=0xffc6a0f6
