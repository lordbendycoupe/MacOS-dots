#!/usr/bin/env zsh
# Swap the Dock/Finder icon of a third-party .app to a given source image.
#
# Usage: set-app-icon.sh /Applications/Name.app /path/to/source.png
#
# Only safe for regular /Applications entries. Anything under
# /System/Applications (Finder, Safari, Calculator, Terminal, Messages...)
# is SIP-protected -- this will fail to write there, on purpose. Don't try
# to work around that (e.g. by disabling SIP) just to reskin a system app.
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

RESOURCES="$APP_PATH/Contents/Resources"
PLIST="$APP_PATH/Contents/Info.plist"

# Backups live OUTSIDE the bundle (a hidden sibling dir), never inside
# Contents/ -- codesign's resource-sealing walk trips over stray files
# there (a Info.plist.bak next to Info.plist got flagged "code object is
# not signed at all / In subcomponent"), so keeping originals inside the
# bundle we're about to re-sign is asking for the same class of problem
# the Icon<CR> cleanup below already deals with once.
BACKUP_DIR="$(dirname "$APP_PATH")/.icon-backups/$(basename "$APP_PATH" .app)"
mkdir -p "$BACKUP_DIR"

# CFBundleIconFile is sometimes given without the .icns extension.
ICON_NAME=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$PLIST" 2>/dev/null || true)
if [[ -z "$ICON_NAME" ]]; then
  echo "error: couldn't read CFBundleIconFile from $PLIST" >&2
  exit 1
fi
[[ "$ICON_NAME" != *.icns ]] && ICON_NAME="${ICON_NAME}.icns"
ICNS_PATH="$RESOURCES/$ICON_NAME"

if [[ ! -f "$ICNS_PATH" ]]; then
  echo "error: expected icon at $ICNS_PATH, not found" >&2
  exit 1
fi

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT
ICONSET="$WORKDIR/icon.iconset"
mkdir -p "$ICONSET"

sips -z 16 16   "$SRC_IMAGE" --out "$ICONSET/icon_16x16.png"      >/dev/null
sips -z 32 32   "$SRC_IMAGE" --out "$ICONSET/icon_16x16@2x.png"   >/dev/null
sips -z 32 32   "$SRC_IMAGE" --out "$ICONSET/icon_32x32.png"      >/dev/null
sips -z 64 64   "$SRC_IMAGE" --out "$ICONSET/icon_32x32@2x.png"   >/dev/null
sips -z 128 128 "$SRC_IMAGE" --out "$ICONSET/icon_128x128.png"    >/dev/null
sips -z 256 256 "$SRC_IMAGE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "$SRC_IMAGE" --out "$ICONSET/icon_256x256.png"    >/dev/null
sips -z 512 512 "$SRC_IMAGE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "$SRC_IMAGE" --out "$ICONSET/icon_512x512.png"    >/dev/null
cp "$ICONSET/icon_512x512.png" "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$WORKDIR/new.icns"

# Keep exactly one backup of whatever the icon was before we ever touched
# it -- re-running this on an app we already themed shouldn't clobber the
# real original with a themed-over-themed copy.
ICNS_BACKUP="$BACKUP_DIR/$(basename "$ICON_NAME")"
if [[ ! -f "$ICNS_BACKUP" ]]; then
  cp "$ICNS_PATH" "$ICNS_BACKUP"
fi
cp "$WORKDIR/new.icns" "$ICNS_PATH"

# Modern app bundles often also carry CFBundleIconName, pointing at a
# compiled asset-catalog entry (Contents/Resources/Assets.car). When
# present, Icon Services prefers THAT over CFBundleIconFile, so replacing
# the .icns alone is invisible. Drop the key (not the .car itself -- it can
# hold other in-app UI assets we don't want to disturb) so resolution falls
# back to the .icns we just wrote. One-time Info.plist backup, same
# once-only pattern as the .icns backup above.
if /usr/libexec/PlistBuddy -c "Print :CFBundleIconName" "$PLIST" >/dev/null 2>&1; then
  if [[ ! -f "$BACKUP_DIR/Info.plist" ]]; then
    cp "$PLIST" "$BACKUP_DIR/Info.plist"
  fi
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$PLIST"
fi

# A leftover Finder "paste a custom icon" artifact (a hidden Icon<CR> file
# plus a com.apple.FinderInfo xattr at the bundle root) makes codesign
# refuse to seal the bundle at all ("resource fork, Finder information, or
# similar detritus not allowed"). We're replacing that fragile per-Finder
# method with a real embedded .icns anyway, so it's safe to clear.
rm -f "$APP_PATH"/Icon$'\r'
xattr -c "$APP_PATH" 2>/dev/null || true

# Replacing a bundle resource invalidates the app's outer code signature,
# so it needs re-signing -- but WITHOUT --deep. Multi-component apps
# (Chrome, Electron apps, Steam) have nested frameworks/helpers/XPC
# services with their own real Developer-ID signatures and entitlements
# (sandboxing, hardened runtime); --deep blindly ad-hoc-resigns all of
# those too, stripping real entitlements and risking a broken sandbox on
# next launch. Only the outer bundle's signature actually needs to change
# here, since only its Resources changed.
codesign --force -s - "$APP_PATH" 2>&1 | grep -v '^$' || true
touch "$APP_PATH"

echo "themed: $APP_PATH ($ICON_NAME)"
