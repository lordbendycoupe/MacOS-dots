#!/usr/bin/env zsh
# Apply juxtopposed.com's pixel-art macOS icon pack to whichever of its
# apps are actually installed on this machine. Safe subset only: apps
# living in /Applications. System apps (Finder, Safari, Terminal, Messages,
# Calculator, etc.) are SIP-protected and deliberately left alone -- see
# set-app-icon.sh.
#
# Usage: apply-icon-pack.sh
# Source: https://www.juxtopposed.com/macos-icons
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
ICONS_DIR="$SCRIPT_DIR/../icons"
mkdir -p "$ICONS_DIR"

# icon-pack filename (no extension) -> installed app path
typeset -A PACK=(
  Ghostty  "/Applications/Ghostty.app"
  Chrome   "/Applications/Google Chrome.app"
  VSCode   "/Applications/Visual Studio Code.app"
  Spotify  "/Applications/Spotify.app"
  Steam    "/Applications/Steam.app"
  Discord  "/Applications/Discord.app"
  Obsidian "/Applications/Obsidian.app"
  Firefox  "/Applications/Firefox.app"
  Figma    "/Applications/Figma.app"
  Telegram "/Applications/Telegram.app"
  Arc      "/Applications/Arc.app"
  Zen      "/Applications/Zen.app"
  Notion   "/Applications/Notion.app"
)

themed=()
skipped=()

for name in "${(@k)PACK}"; do
  app_path="${PACK[$name]}"
  [[ ! -d "$app_path" ]] && { skipped+=("$name (not installed)"); continue; }

  png="$ICONS_DIR/$name.png"
  if [[ ! -f "$png" ]]; then
    if ! curl -sf -A "Mozilla/5.0" -o "$png" "https://www.juxtopposed.com/$name.png"; then
      rm -f "$png"
      skipped+=("$name (icon download failed)")
      continue
    fi
  fi

  if "$SCRIPT_DIR/set-app-icon.sh" "$app_path" "$png"; then
    themed+=("$name")
  else
    skipped+=("$name (set-app-icon.sh failed)")
  fi
done

killall Finder Dock 2>/dev/null || true

echo
echo "Themed: ${themed[*]:-none}"
echo "Skipped: ${skipped[*]:-none}"
