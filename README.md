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

What it can't do for you: grant AeroSpace/borders/AutoRaise **Accessibility** permission (System Settings → Privacy & Security → Accessibility), or grant your terminal app **App Management** permission (System Settings → Privacy & Security → App Management, needed by the icon-pack theming to edit other apps' bundles) — macOS requires both to be a manual, physical click. The script's summary reminds you.

## Tools this installs/configures

| Tool | Install method | Source |
|---|---|---|
| AeroSpace | `brew install --cask nikitabobko/tap/aerospace` | github.com/nikitabobko/AeroSpace |
| SketchyBar | `brew install felixkratz/formulae/sketchybar` | github.com/FelixKratz/SketchyBar |
| borders | `brew install felixkratz/formulae/borders` | github.com/FelixKratz/JankyBorders |
| AutoRaise | `brew install autoraise` | focus-follows-mouse |
| Alacritty / Ghostty | `brew install --cask alacritty` / `ghostty` | terminals |
| tmux | `brew install tmux` | terminal multiplexer, plugins via TPM |
| Nerd/coding fonts | `brew install --cask font-*` | Hack Nerd, Iosevka, JetBrains Mono Nerd, Maple Mono NF |

All of the above have real Homebrew formulas/casks, so `bootstrap.sh` never builds anything from source.

## Repo layout

```
alacritty/    alacritty.toml, themes/
ghostty/      config, auto/
tmux/         tmux.conf -> ~/.config/tmux/tmux.conf; plugins via TPM (not vendored, cloned by bootstrap.sh)
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
- **App icon theming** (`scripts/set-app-icon.sh`, `scripts/apply-icon-pack.sh`): swaps an app's `.icns` for a PNG, re-signs the bundle (ad-hoc, **without** `--deep` — multi-component apps like Chrome/Electron apps have nested frameworks/helpers with real Developer-ID signatures and sandbox entitlements that `--deep` would strip), and strips any leftover Finder "paste a custom icon" artifact (a hidden `Icon\r` file + `com.apple.FinderInfo` xattr) that would otherwise make codesign refuse to seal the bundle. `apply-icon-pack.sh` runs this against whichever apps from [juxtopposed.com/macos-icons](https://www.juxtopposed.com/macos-icons) are actually installed (`icons/*.png`, downloading any missing ones). Only ever targets regular `/Applications` entries — anything under `/System/Applications` (Finder, Safari, Terminal, Messages, Calculator, ...) is SIP-protected and deliberately left alone. Writing into another app's bundle also needs **App Management** permission granted to whichever terminal runs the script (macOS TCC gate); this can be re-required after the *target* app updates and re-signs itself, not just once up front.
  - The pack's source PNGs (`icons/*.png`) are free-form shapes on a transparent background (Yosemite-style — a circular/blob glyph, not a full-bleed square). macOS 26 auto-generates a grey backplate behind any Dock icon that isn't a full-bleed rounded-square ("squircle"), so left as-is these all get boxed in grey. Each PNG here has been recomposited to fill the squircle edge-to-edge in its own color before being applied, which avoids that. A couple of the pack's icons (e.g. Spotify's soundwaves) draw part of the glyph as a fully transparent cutout rather than an opaque stroke, relying on whatever's behind the icon to show through — naively filling the squircle would paint over those and erase the glyph, so cutouts enclosed by opaque content (not reachable from the canvas edge) get filled opaque white instead of the squircle's fill color.
  - **Discord** is themed via a Dock-shortcut wrapper (`~/Applications/Discord.app`, pinned in the Dock in place of the real app — same `osacompile`-built `tell application id "com.hnc.Discord" to activate` trick used for Messages/Calendar/Notes/etc.), not by editing `/Applications/Discord.app` directly. Discord self-updates (Squirrel) and silently overwrites its own `.icns` on every update, wiping the theming; the wrapper's icon isn't touched by Discord's updater so it survives.
  - **`set-app-icon.sh`'s re-sign approach crashes multi-process Electron/Chromium apps on their next launch** — confirmed on this machine for Discord, Chrome, VS Code, Obsidian, Steam, and Spotify. Ad-hoc re-signing the *outer* bundle while its nested `*.app` Helper processes (renderer, GPU, network, ...) keep their original Developer-ID signature creates a parent/child signature mismatch; Chromium's sandbox rejects it and the renderer crashes immediately on launch (Crashpad reports a fatal error, the app never opens). `--deep` doesn't fix it either — TCC's App Management gate blocks writes into the nested `Helper.app` bundles even when the outer app was already permitted. The fix if this happens: `brew reinstall --cask <app>` (redownloads a properly-signed copy; Homebrew-cask apps only — check with `brew list --cask`) restores it. This is why `scripts/set-finder-icon.sh` exists (below) — use it for anything Electron/Chromium-based instead of `set-app-icon.sh`.
- **`scripts/set-finder-icon.sh`**: the safe alternative to `set-app-icon.sh` for multi-process apps. Sets a Finder/Icon-Services-level icon override (`NSWorkspace setIcon:forFile:`, the same mechanism as dragging an image onto an app in Get Info) instead of replacing the bundle's `.icns` and re-signing — it never touches the code signature, `Info.plist`, or `Contents/Resources`, so there's nothing to break. Both Finder and the Dock resolve icons through the same Icon Services APIs this uses, so it shows up in both. `apply-icon-pack.sh` uses this by default for everything in its `PACK` table, falling back to `set-app-icon.sh` only for apps listed in `RESIGN_METHOD` (currently just IntelliJ, where this method inexplicably fails — `NSWorkspace` returns `false` for reasons not yet root-caused, even though IntelliJ itself is a JVM app with no signature-mismatch risk, so the re-sign method is fine for it).
- **A single app's icon can end up genuinely corrupted, not just cached** — happened to Ghostty (Dock/Finder started showing a plain purple folder icon instead of any app icon at all, confirmed at the `NSWorkspace` API level, not a Dock rendering-cache issue). Root cause unconfirmed but likely compounding: an `.icns` swap via `set-app-icon.sh` layered on top of unrelated icon tampering that predated this repo's scripts. Fix was the same as the Electron-crash fix above: `brew reinstall --cask <app>` for a clean baseline, then re-theme with `set-finder-icon.sh`. If an icon looks wrong in a way cache-clearing doesn't fix, verify by asking `NSWorkspace sharedWorkspace iconForFile:` directly (bypasses Dock/Finder's cache) before assuming it's just stale.
- **tmux** (`tmux/tmux.conf` -> `~/.config/tmux/tmux.conf`): prefix remapped `C-b` -> `C-a` (screen-style; `C-a a` sends a literal `C-a` through to the shell/readline), vi copy-mode bound to macOS's `pbcopy`, vim-mnemonic split binds (`|`/`-`), and a status bar re-using the same moonfly-neutrals + Catppuccin-Macchiato-accents palette as `ghostty/config`. Plugins via [TPM](https://github.com/tmux-plugins/tpm) (not vendored — `bootstrap.sh`'s `install_tmux_plugins` clones it and runs its install script against a throwaway tmux session): `tmux-sensible`, `tmux-yank`, `tmux-resurrect` + `tmux-continuum` (auto-save every 15 min, auto-restore on tmux start — same "don't lose your layout" instinct as the AeroSpace workspace-persistence LaunchAgent above, just for panes/sessions instead of window-to-workspace mapping), and `vim-tmux-navigator` (seamless `C-h/j/k/l` pane movement across tmux splits *and* Neovim splits) — the Neovim side of that last one needs a matching plugin in your (deliberately-excluded-from-this-repo) nvim config to work bidirectionally; without it, `C-hjkl` still moves between tmux panes fine, just won't hop into/out of Neovim splits.

## Deliberately excluded

nvim, spicetify (Spotify theming), pywal, neofetch, and Raycast configs are more personal/unrelated to the WM/terminal setup and aren't in this repo. No SSH keys, tokens, or other secrets are (or should ever be) committed here.
