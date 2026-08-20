#!/usr/bin/env zsh
# Chrome's Picture-in-Picture window is marked 'layout floating' in
# aerospace.toml so it never gets pulled into a tiled layout, but AeroSpace
# has no "present on all workspaces" concept -- a floating window still
# belongs to exactly one workspace. This runs on every workspace change
# (see exec-on-workspace-change in aerospace.toml) and relocates any open
# PiP window to whichever workspace just became focused, so it's always
# wherever you currently are.
#
# Hardcoded: launchd/AeroSpace's exec environment PATH doesn't reliably
# include /opt/homebrew/bin, same reason save-layout.sh hardcodes it.
AEROSPACE=/opt/homebrew/bin/aerospace
JQ=/usr/bin/jq

FOCUSED_WORKSPACE="$1"
[[ -z "$FOCUSED_WORKSPACE" ]] && exit 0

"$AEROSPACE" list-windows --all --json 2>/dev/null \
  | "$JQ" -r --arg ws "$FOCUSED_WORKSPACE" '
      .[] | select(.["app-name"] == "Google Chrome")
          | select(.["window-title"] | test("Picture.in.Picture"; "i"))
          | .["window-id"]
    ' \
  | while read -r win_id; do
      [[ -z "$win_id" ]] && continue
      cur_ws=$("$AEROSPACE" list-windows --all --format '%{window-id} %{workspace}' 2>/dev/null \
        | awk -v id="$win_id" '$1 == id {print $2}')
      [[ "$cur_ws" == "$FOCUSED_WORKSPACE" ]] && continue
      "$AEROSPACE" move-node-to-workspace --window-id "$win_id" "$FOCUSED_WORKSPACE" 2>/dev/null
    done
