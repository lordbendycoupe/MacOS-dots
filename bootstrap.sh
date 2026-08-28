#!/usr/bin/env bash
# Interactive installer/linker for this dotfiles repo. Meant to be run on a
# similar-spec Apple Silicon MacBook (this was built/tested on one). Safe
# to re-run: existing real files/dirs at a destination get backed up once
# (*.pre-bootstrap.bak) rather than clobbered, and already-correct symlinks
# are left alone.
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLED=()
SKIPPED=()
LINKED=()

confirm() {
  # $1 = prompt. Returns 0 for yes.
  local reply
  read -r -p "$1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then return 0; fi
  if confirm "Homebrew isn't installed. Install it now? (required for everything below)"; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo "Can't continue without Homebrew. Exiting."
    exit 1
  fi
}

# name | check-command | install-command | description
TOOLS=(
  "Alacritty|[ -d '/Applications/Alacritty.app' ]|brew install --cask alacritty|terminal emulator"
  "Ghostty|[ -d '/Applications/Ghostty.app' ]|brew install --cask ghostty|terminal emulator"
  "AeroSpace|command -v aerospace|brew install --cask nikitabobko/tap/aerospace|tiling window manager (github.com/nikitabobko/AeroSpace)"
  "SketchyBar|command -v sketchybar|brew install felixkratz/formulae/sketchybar|status bar (github.com/FelixKratz/SketchyBar)"
  "borders|command -v borders|brew install felixkratz/formulae/borders|window border highlighting (github.com/FelixKratz/JankyBorders)"
  "AutoRaise|command -v autoraise|brew install autoraise|focus-follows-mouse"
  "jq|command -v jq|brew install jq|needed by aerospace/scripts/pip-follow.sh"
  "font-hack-nerd-font|brew list --cask font-hack-nerd-font >/dev/null 2>&1|brew install --cask font-hack-nerd-font|sketchybar/terminal glyphs"
  "font-iosevka|brew list --cask font-iosevka >/dev/null 2>&1|brew install --cask font-iosevka|terminal font"
  "font-jetbrains-mono-nerd-font|brew list --cask font-jetbrains-mono-nerd-font >/dev/null 2>&1|brew install --cask font-jetbrains-mono-nerd-font|terminal font"
  "font-maple-mono-nf|brew list --cask font-maple-mono-nf >/dev/null 2>&1|brew install --cask font-maple-mono-nf|terminal font"
  "tmux|command -v tmux|brew install tmux|terminal multiplexer"
)

install_tools() {
  ensure_brew
  for entry in "${TOOLS[@]}"; do
    IFS='|' read -r name check install desc <<< "$entry"
    if eval "$check" >/dev/null 2>&1; then
      continue
    fi
    if confirm "$name ($desc) is missing. Install with: $install ?"; then
      eval "$install"
      INSTALLED+=("$name")
    else
      SKIPPED+=("$name")
    fi
  done
}

# link SOURCE (repo-relative) DEST (absolute)
link() {
  local src="$REPO_DIR/$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ -e "$dst" || -L "$dst" ]]; then
    mv "$dst" "$dst.pre-bootstrap.bak"
  fi
  ln -s "$src" "$dst"
  LINKED+=("$dst -> $src")
}

link_dotfiles() {
  link "alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  link "alacritty/themes"         "$HOME/.config/alacritty/themes"
  link "ghostty/config"           "$HOME/.config/ghostty/config"
  link "ghostty/auto"             "$HOME/.config/ghostty/auto"
  link "aerospace/aerospace.toml" "$HOME/.config/aerospace/aerospace.toml"
  link "aerospace/scripts"        "$HOME/.config/aerospace/scripts"
  link "sketchybar/sketchybarrc"  "$HOME/.config/sketchybar/sketchybarrc"
  link "sketchybar/plugins"       "$HOME/.config/sketchybar/plugins"
  link "sketchybar/icons"         "$HOME/.config/sketchybar/icons"
  link "borders/bordersrc"        "$HOME/.config/borders/bordersrc"
  link "AutoRaise/config"         "$HOME/.config/AutoRaise/config"
  link "zsh/zshrc"                "$HOME/.zshrc"
  link "zsh/zprofile"             "$HOME/.zprofile"
  link "zsh/zshenv"               "$HOME/.zshenv"
  link "git/ignore"               "$HOME/.config/git/ignore"
  git config --global core.excludesfile "$HOME/.config/git/ignore" 2>/dev/null || true
  link "tmux/tmux.conf"           "$HOME/.config/tmux/tmux.conf"
}

install_tmux_plugins() {
  local tpm_dir="$HOME/.config/tmux/plugins/tpm"
  if [[ ! -d "$tpm_dir" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir" >/dev/null 2>&1
  fi
  # TPM's install script needs a running tmux server to attach plugins to.
  tmux new-session -d -s _bootstrap 2>/dev/null || true
  tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true
  "$tpm_dir/scripts/install_plugins.sh" >/dev/null 2>&1
  tmux kill-session -t _bootstrap 2>/dev/null || true
}

install_launchagent() {
  local template="$REPO_DIR/aerospace/launchagents/com.user.aerospace-layout-saver.plist.template"
  local dest="$HOME/Library/LaunchAgents/com.user.aerospace-layout-saver.plist"
  mkdir -p "$HOME/Library/LaunchAgents"
  sed "s#__HOME__#$HOME#g" "$template" > "$dest"
  launchctl unload "$dest" >/dev/null 2>&1 || true
  launchctl load "$dest" 2>/dev/null || true
}

offer_icon_pack() {
  if confirm "Apply the juxtopposed.com pixel-art icon pack to matching installed apps?"; then
    "$REPO_DIR/scripts/apply-icon-pack.sh"
  fi
}

main() {
  echo "== MacOS-dots bootstrap =="
  install_tools
  echo
  echo "== Linking dotfiles =="
  link_dotfiles
  echo
  echo "== Installing layout-saver LaunchAgent =="
  install_launchagent
  echo
  echo "== Installing tmux plugins (TPM) =="
  install_tmux_plugins
  echo
  offer_icon_pack

  echo
  echo "== Summary =="
  echo "Installed: ${INSTALLED[*]:-none}"
  echo "Skipped:   ${SKIPPED[*]:-none}"
  echo "Linked:    ${#LINKED[@]} paths"
  echo
  echo "Manual steps this script can't do for you:"
  echo "  - Grant AeroSpace, borders, and AutoRaise Accessibility permission in"
  echo "    System Settings -> Privacy & Security -> Accessibility."
  echo "  - Log out/in (or run: aerospace enable && open -a AeroSpace) to start AeroSpace,"
  echo "    then: brew services start sketchybar; brew services start borders; brew services start autoraise"
}

main
