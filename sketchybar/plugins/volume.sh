#!/usr/bin/env bash

BOX=0xff8aadf4
DARK=0xff24273a

update() {
  VOLUME="$1"
  MUTED="$2"

  # Some outputs (e.g. an external monitor's fixed-volume speakers) have no
  # software volume control at all -- AppleScript reports "missing value"
  # rather than a percentage in that case. Show the output device name
  # instead of a broken "missing value%" label.
  if [ -z "$VOLUME" ] || [ "$VOLUME" = "missing value" ]; then
    DEVICE="$(SwitchAudioSource -c 2>/dev/null)"
    if [ -z "$DEVICE" ]; then
      DEVICE="$(system_profiler SPAudioDataType 2>/dev/null | awk '/Default Output Device: Yes/{found=1} found && /:$/{gsub(/:$/,"");gsub(/^ */,"");print;exit}')"
    fi
    sketchybar --set "$NAME" icon=$'' icon.color="$DARK" label="${DEVICE:-Fixed}" label.color="$DARK" background.color="$BOX"
    return
  fi

  if [ "$MUTED" = "true" ]; then
    ICON="󰖁"
  else
    case "$VOLUME" in
      [6-9][0-9]|100) ICON="󰕾" ;;
      [3-5][0-9]) ICON="󰖀" ;;
      [1-9]|[1-2][0-9]) ICON="󰕿" ;;
      *) ICON="󰖁" ;;
    esac
  fi

  sketchybar --set "$NAME" icon="$ICON" icon.color="$DARK" label="${VOLUME}%" label.color="$DARK" background.color="$BOX"
}

case "$SENDER" in
"volume_change")
  update "$INFO" "false"
  ;;
"mouse.scrolled")
  CURRENT="$(osascript -e 'output volume of (get volume settings)' 2>/dev/null)"
  case "$CURRENT" in
    ''|*[!0-9]*) ;;
    *)
      STEP=5
      if [ "$SCROLL_DELTA" -lt 0 ] 2>/dev/null; then STEP=-5; fi
      NEW=$((CURRENT + STEP))
      [ "$NEW" -gt 100 ] && NEW=100
      [ "$NEW" -lt 0 ] && NEW=0
      osascript -e "set volume output volume $NEW" 2>/dev/null
      update "$NEW" "false"
      ;;
  esac
  ;;
*)
  SETTINGS="$(osascript -e 'get volume settings' 2>/dev/null)"
  VOL="$(printf '%s' "$SETTINGS" | sed -n 's/.*output volume:\([^,]*\).*/\1/p')"
  MUTED="$(printf '%s' "$SETTINGS" | sed -n 's/.*output muted:\([^,]*\).*/\1/p')"
  update "$VOL" "$MUTED"
  ;;
esac
