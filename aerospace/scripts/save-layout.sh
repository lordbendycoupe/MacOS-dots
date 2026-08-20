#!/usr/bin/env zsh
# Snapshots which workspace each open window belongs to, keyed by app
# bundle-id (stable across relaunches, unlike window-id). Written on a
# timer by the aerospace-layout-saver LaunchAgent (independent of
# AeroSpace's own process, so a crash/restart of AeroSpace doesn't stop
# state capture) and after every workspace change. restore-layout.py reads
# this back on the next AeroSpace startup.
#
# Only tracks workspace membership, not split ratios/tree position --
# AeroSpace has no serialization for the tiling tree itself.

STATE_FILE="$HOME/.config/aerospace/workspace-state.json"
TMP_FILE="${STATE_FILE}.tmp.$$"
# Hardcoded: launchd's default PATH for LaunchAgents is just
# /usr/bin:/bin:/usr/sbin:/sbin, so a bare `aerospace` silently resolves
# to nothing when this runs via the layout-saver LaunchAgent.
AEROSPACE=/opt/homebrew/bin/aerospace

typeset -A ws_lists

while IFS='|' read -r bid ws; do
  [[ -z "$bid" || -z "$ws" ]] && continue
  if [[ -n "${ws_lists[$bid]}" ]]; then
    ws_lists[$bid]="${ws_lists[$bid]},$ws"
  else
    ws_lists[$bid]="$ws"
  fi
done < <("$AEROSPACE" list-windows --all --format '%{app-bundle-id}|%{workspace}' 2>/dev/null)

# Nothing open / aerospace not reachable -- don't clobber a good snapshot
# with an empty one.
[[ ${#ws_lists} -eq 0 ]] && exit 0

{
  print -n "{"
  local first=1
  for bid in "${(@k)ws_lists}"; do
    [[ $first -eq 0 ]] && print -n ","
    first=0
    printf '\n  "%s": ["%s"]' "$bid" "${ws_lists[$bid]//,/\", \"}"
  done
  print "\n}"
} > "$TMP_FILE"

mv "$TMP_FILE" "$STATE_FILE"
