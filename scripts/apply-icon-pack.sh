#!/usr/bin/env zsh
# Apply juxtopposed.com's pixel-art macOS icon pack to whichever of its
# apps are actually installed on this machine, plus any Dock shortcut
# apps standing in for SIP-protected system apps.
#
# Regular apps: safe subset only, apps living in /Applications. System
# apps (Finder, Safari, Terminal, Calculator, etc.) are SIP-protected and
# deliberately left alone -- see set-app-icon.sh.
#
# Dock shortcuts: some SIP-protected apps (Messages, Calendar, Notes, App
# Store, System Settings, Launchpad, ...) have a small Automator "applet"
# wrapper in ~/Applications instead (just does
# `tell application id "..." to activate`), pinned to the Dock in place of
# the real app -- that's what actually gets a themed icon, since the real
# app under /System/Applications can't be touched. These are personal to
# this machine; bootstrap.sh doesn't recreate them on a fresh install.
#
# Two theming methods, picked per app -- see set-app-icon.sh and
# set-finder-icon.sh for why:
#   - set-app-icon.sh replaces the .icns and ad-hoc re-signs the bundle.
#     Breaks any multi-process Electron/Chromium app (confirmed: Discord,
#     Chrome, VS Code, Obsidian, Steam, Spotify all crash on next launch
#     after this -- ad-hoc-signing the outer bundle while its nested
#     Helper.app processes keep their real Developer-ID signature creates
#     a parent/child mismatch Chromium's sandbox rejects). Safe for
#     single-process apps (Ghostty) and simple osacompile applets (the
#     Dock-shortcut wrappers).
#   - set-finder-icon.sh sets a Finder/Icon-Services-level icon override
#     instead (NSWorkspace setIcon:forFile:) and never touches the code
#     signature at all, so it's safe for Electron/Chromium apps. Default
#     for everything in PACK except IntelliJ, where it inexplicably fails
#     (NSWorkspace returns false, cause unconfirmed) even though IntelliJ
#     itself is a JVM app with no signature-mismatch risk -- set-app-icon.sh
#     is proven safe for it, so it stays on that method.
#
# Usage: apply-icon-pack.sh
# Source: https://www.juxtopposed.com/macos-icons
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/../icons"
mkdir -p "$ICONS_DIR"

# icon-pack filename (no extension) -> installed app path.
#
# IntelliJ isn't part of juxtopposed's pack -- JetBrains hasn't shipped
# macOS 26's new adaptive-icon format, so the OS was rendering its own
# generic simplified glyph for it. IntelliJ.png here is a hand-made "IJ"
# monogram in the same pixel style as the rest of the pack, so there's no
# download fallback for it in theme_target() below; if icons/IntelliJ.png
# ever goes missing, regenerate it rather than expecting a curl to work.
typeset -A PACK=(
  Ghostty  "/Applications/Ghostty.app"
  Chrome   "/Applications/Google Chrome.app"
  VSCode   "/Applications/Visual Studio Code.app"
  Spotify  "/Applications/Spotify.app"
  Steam    "/Applications/Steam.app"
  Obsidian "/Applications/Obsidian.app"
  IntelliJ "/Applications/IntelliJ IDEA.app"
  Firefox  "/Applications/Firefox.app"
  Figma    "/Applications/Figma.app"
  Telegram "/Applications/Telegram.app"
  Arc      "/Applications/Arc.app"
  Zen      "/Applications/Zen.app"
  Notion   "/Applications/Notion.app"
)

# icon-pack filename (no extension) -> Dock-shortcut applet path. Label on
# disk doesn't always match the pack's filename (e.g. "System Settings"
# shortcut, "Settings" icon), hence a separate table instead of reusing PACK.
#
# Discord lives here too, not in PACK: Discord.app self-updates (Squirrel),
# which silently overwrites its .icns and re-signs the bundle on every
# update, wiping the theming and sometimes even breaking write access until
# App Management permission is re-granted. Theming a small `osacompile`
# wrapper app instead (tell application id "com.hnc.Discord" to activate)
# means the Dock icon survives Discord's own updates untouched -- pin
# ~/Applications/Discord.app in the Dock in place of the real app.
typeset -A DOCK_SHORTCUTS=(
  Launchpad "$HOME/Applications/Apps.app"
  Messages  "$HOME/Applications/Messages.app"
  Calendar  "$HOME/Applications/Calendar.app"
  Notes     "$HOME/Applications/Notes.app"
  Appstore  "$HOME/Applications/App Store.app"
  Settings  "$HOME/Applications/System Settings.app"
  Discord   "$HOME/Applications/Discord.app"
)

# Apps where set-app-icon.sh (re-sign) is known-safe and should be used
# instead of the default set-finder-icon.sh (Finder-icon override).
typeset -A RESIGN_METHOD=(
  IntelliJ 1
)

themed=()
skipped=()

theme_target() {
  local name="$1" app_path="$2" script="$3"
  [[ ! -d "$app_path" ]] && { skipped+=("$name (not installed)"); return; }

  local png="$ICONS_DIR/$name.png"
  if [[ ! -f "$png" ]]; then
    if ! curl -sf -A "Mozilla/5.0" -o "$png" "https://www.juxtopposed.com/$name.png"; then
      rm -f "$png"
      skipped+=("$name (icon download failed)")
      return
    fi
  fi

  if "$SCRIPT_DIR/$script" "$app_path" "$png"; then
    themed+=("$name")
  else
    skipped+=("$name ($script failed)")
  fi
}

for name in "${(@k)PACK}"; do
  script="set-finder-icon.sh"
  [[ -n "${RESIGN_METHOD[$name]:-}" ]] && script="set-app-icon.sh"
  theme_target "$name" "${PACK[$name]}" "$script"
done
for name in "${(@k)DOCK_SHORTCUTS}"; do
  theme_target "$name" "${DOCK_SHORTCUTS[$name]}" "set-app-icon.sh"
done

killall Finder Dock 2>/dev/null || true

echo
echo "Themed: ${themed[*]:-none}"
echo "Skipped: ${skipped[*]:-none}"
