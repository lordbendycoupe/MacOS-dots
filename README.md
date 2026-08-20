# MacOS-dots

Personal macOS window-manager/terminal dotfiles: AeroSpace (tiling WM), SketchyBar (status bar), borders, AutoRaise (focus-follows-mouse), Alacritty + Ghostty (terminals), zsh, plus a couple of small scripts for theming app icons. Built and tested on an Apple Silicon MacBook.

This repo is meant to be pulled onto another, similarly-specced Apple Silicon Mac and reproduced with one command:

```
git clone https://github.com/lordbendycoupe/MacOS-dots.git
cd MacOS-dots
./bootstrap.sh
```

## What `bootstrap.sh` does

1. Checks for Homebrew (offers to install it if missing — everything else depends on it).
2. For each tool below, checks whether it's already installed; if not, shows you the exact `brew` command it wants to run and asks y/n before running it. Anything you decline is listed in the end-of-run summary so nothing silently fails to configure.
3. Symlinks every config in this repo into its real location (e.g. `aerospace/aerospace.toml` → `~/.config/aerospace/aerospace.toml`). If something real already lives at the destination, it's moved aside to `<name>.pre-bootstrap.bak` first — nothing is silently overwritten. Re-running the script is safe; already-correct symlinks are left alone.
4. Installs the `aerospace-layout-saver` LaunchAgent (the template has your home directory substituted in, since `launchd` plists don't expand `$HOME`).
5. Offers to run the icon-pack theming (see below).

What it can't do for you: grant AeroSpace/borders/AutoRaise **Accessibility** permission (System Settings → Privacy & Security → Accessibility) — macOS requires that to be a manual, physical click. The script's summary reminds you.

## Tools this installs/configures

| Tool | Install method | Source |
|---|---|---|
| AeroSpace | `brew install --cask nikitabobko/tap/aerospace` | github.com/nikitabobko/AeroSpace |
| SketchyBar | `brew install felixkratz/formulae/sketchybar` | github.com/FelixKratz/SketchyBar |
| borders | `brew install felixkratz/formulae/borders` | github.com/FelixKratz/JankyBorders |
| AutoRaise | `brew install autoraise` | focus-follows-mouse |
| Alacritty / Ghostty | `brew install --cask alacritty` / `ghostty` | terminals |
| Nerd/coding fonts | `brew install --cask font-*` | Hack Nerd, Iosevka, JetBrains Mono Nerd, Maple Mono NF |

All of the above have real Homebrew formulas/casks, so `bootstrap.sh` never builds anything from source.

## Repo layout

```
alacritty/    alacritty.toml, themes/
ghostty/      config, auto/
aerospace/    aerospace.toml (portable: $HOME, not a hardcoded username)
              scripts/          -- workspace-layout persistence + PiP-follow (below)
              launchagents/     -- LaunchAgent .plist.template (__HOME__ placeholder)
sketchybar/   sketchybarrc, plugins/, icons/
borders/      bordersrc
AutoRaise/    config
zsh/          zshrc, zprofile, zshenv  -> symlinked to ~/.zshrc etc.
git/          ignore                   -> global gitignore (core.excludesfile)
icons/        source PNGs for the icon-pack theming below
scripts/      set-app-icon.sh, apply-icon-pack.sh
```

## Notable non-obvious behavior

- **Workspace layout persistence** (`aerospace/scripts/save-layout.sh` + `restore-layout.py` + `restore-layout-loop.sh`): a LaunchAgent snapshots which workspace every window belongs to (by bundle ID) every 10s and after every workspace switch, so an AeroSpace crash/restart or a full reboot restores your layout instead of dumping everything onto one workspace. AeroSpace has no tree/split-ratio serialization, so only workspace membership is restored, not exact tiling positions.
- **Chrome Picture-in-Picture follows you across workspaces** (`aerospace/scripts/pip-follow.sh`): AeroSpace has no "present on all workspaces" concept ([nikitabobko/AeroSpace#2](https://github.com/nikitabobko/AeroSpace/issues/2), still open). The PiP window is set to float (via an `on-window-detected` rule matching Chrome + a title regex for "Picture-in-Picture") so it's never tiled, and this script — hooked into `exec-on-workspace-change` — actively relocates it to whichever workspace you just switched to. It's not simultaneous presence, it's "moves with you within about one keystroke."
- **App icon theming** (`scripts/set-app-icon.sh`, `scripts/apply-icon-pack.sh`): swaps an app's `.icns` for a PNG, re-signs the bundle (ad-hoc, **without** `--deep` — multi-component apps like Chrome/Electron apps have nested frameworks/helpers with real Developer-ID signatures and sandbox entitlements that `--deep` would strip), and strips any leftover Finder "paste a custom icon" artifact (a hidden `Icon\r` file + `com.apple.FinderInfo` xattr) that would otherwise make codesign refuse to seal the bundle. `apply-icon-pack.sh` runs this against whichever apps from [juxtopposed.com/macos-icons](https://www.juxtopposed.com/macos-icons) are actually installed (`icons/*.png`, downloading any missing ones). Only ever targets regular `/Applications` entries — anything under `/System/Applications` (Finder, Safari, Terminal, Messages, Calculator, ...) is SIP-protected and deliberately left alone.

## Deliberately excluded

nvim, spicetify (Spotify theming), pywal, neofetch, and Raycast configs are more personal/unrelated to the WM/terminal setup and aren't in this repo. No SSH keys, tokens, or other secrets are (or should ever be) committed here.
