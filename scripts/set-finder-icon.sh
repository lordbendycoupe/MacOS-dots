#!/usr/bin/env zsh
# Give an app a custom icon via Finder's "paste image in Get Info" mechanism
# (NSWorkspace setIcon:forFile:) instead of replacing its .icns and
# re-signing the bundle.
#
# Why this exists: set-app-icon.sh's approach (replace the .icns, ad-hoc
# re-sign the outer bundle) breaks any multi-process Electron/Chromium app
# (Discord, Chrome, VS Code, Obsidian, Steam, Spotify, ...). Ad-hoc signing
# the outer bundle while its nested Helper.app processes keep their
# original Developer-ID signature creates a parent/child signature mismatch
# that Chromium's sandbox rejects outright -- the renderer process crashes
# on launch (confirmed via Crashpad fatal reports on this exact machine).
# `codesign --deep` doesn't reliably fix it either (TCC blocks writes into
# nested helper bundles even with App Management granted for the outer app).
#
# This method sets a Finder/Icon-Services-level icon override instead: a
# resource fork + com.apple.FinderInfo xattr on the app bundle itself. It
# never touches Contents/Resources/*.icns, Info.plist, or the code
# signature, so there's nothing to re-sign and no launch risk. Both Finder
# and the Dock resolve icons through the same Icon Services APIs this uses,
# so it shows up in both places. Single-process native apps (Ghostty, and
# anything under /System/Applications you're not supposed to touch anyway)
# can still use set-app-icon.sh if you prefer, but for anything Electron/
# Chromium-based, always use this instead.
#
# Usage: set-finder-icon.sh /Applications/Name.app /path/to/source.png
set -euo pipefail

APP_PATH="$1"
SRC_IMAGE="$2"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: $APP_PATH not found" >&2
  exit 1
fi
if [[ ! -f "$SRC_IMAGE" ]]; then
  echo "error: $SRC_IMAGE not found" >&2
  exit 1
fi

osascript <<APPLESCRIPT
use framework "Cocoa"
use scripting additions

set imgPath to "$SRC_IMAGE"
set targetPath to "$APP_PATH"

set theImage to current application's NSImage's alloc()'s initWithContentsOfFile:imgPath
if theImage is missing value then
  error "could not load image at " & imgPath
end if

set ok to current application's NSWorkspace's sharedWorkspace()'s setIcon:theImage forFile:targetPath options:0
if ok is false then
  error "NSWorkspace setIcon:forFile: returned false for " & targetPath
end if
APPLESCRIPT

echo "themed (Finder icon, no re-sign): $APP_PATH"
