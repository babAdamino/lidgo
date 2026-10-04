#!/usr/bin/env bash
# build.sh — compile lidgo.app from source with the Command Line Tools only.
#
# No Xcode project, no Package.swift: just `swiftc` + a hand-assembled .app bundle,
# ad-hoc signed. Works from any clone (no hardcoded paths or usernames).
#
# Usage:
#   ./build.sh                      # build into ./build/lidgo.app
#   ./build.sh /Applications        # build straight into /Applications
#   DEST=/Applications ./build.sh   # same, via env
#
# Icons: assets/lidgo.icns (Dock/Finder, rendered from "assets/Icon Exports")
# and menubaricon.png (menu-bar glyph) are checked in and copied as-is.
# It NEVER touches sudo, sleep settings, or the menu bar. Use install.sh for the
# passwordless grant + login item.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="lidgo"
# macOS arm64 target. lidgo is verified on macOS 26 (Tahoe) / Apple Silicon.
# Override with TARGET=... (e.g. CI on a runner whose SDK predates macOS 26).
TARGET="${TARGET:-arm64-apple-macos26.0}"

# Destination: first arg, else $DEST, else ./build
DEST="${DEST:-}"
for arg in "$@"; do
  DEST="$arg"
done
DEST="${DEST:-$REPO/build}"

APP="$DEST/$APP_NAME.app"
CONTENTS="$APP/Contents"

echo "==> Building $APP_NAME.app"
echo "    repo:   $REPO"
echo "    dest:   $DEST"
echo "    target: $TARGET"

command -v swiftc >/dev/null || { echo "error: swiftc not found. Install the Command Line Tools: xcode-select --install" >&2; exit 1; }

# 1. Required artwork (both checked in).
ICNS="$REPO/assets/$APP_NAME.icns"
MENUICON="$REPO/menubaricon.png"
[ -f "$ICNS" ] || { echo "error: missing $ICNS" >&2; exit 1; }
[ -f "$MENUICON" ] || { echo "error: missing $MENUICON (the menu-bar glyph source)" >&2; exit 1; }

# 2. Compile the executable.
echo "==> Compiling App.swift"
BIN_TMP="$(mktemp -d)"
swiftc -O -parse-as-library -target "$TARGET" -framework AppKit -framework ServiceManagement \
  "$REPO/App.swift" -o "$BIN_TMP/$APP_NAME"

# 3. Assemble the bundle: Contents/{Info.plist, MacOS/<exe>, Resources/<name>.icns}
echo "==> Assembling bundle"
rm -rf "$APP"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
cp "$REPO/Info.plist" "$CONTENTS/Info.plist"
cp "$BIN_TMP/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"
cp "$ICNS" "$CONTENTS/Resources/$APP_NAME.icns"
cp "$MENUICON" "$CONTENTS/Resources/menubaricon.png"
chmod +x "$CONTENTS/MacOS/$APP_NAME"
# Strip the symbol table (~35KB saved on a binary this small; verified 151K -> 116K).
# Safe here because the ad-hoc sign in step 4 happens after the strip.
strip -x "$CONTENTS/MacOS/$APP_NAME"
# Ship the grant + uninstall scripts inside the bundle so Homebrew-cask users (who get
# only the .app) can run the one-time passwordless grant and a clean uninstall.
cp "$REPO/grant.sh" "$REPO/uninstall.sh" "$CONTENTS/Resources/"
chmod +x "$CONTENTS/Resources/grant.sh" "$CONTENTS/Resources/uninstall.sh"
rm -rf "$BIN_TMP"

# 4. Ad-hoc sign (no Apple Developer ID needed; trust comes from building it yourself).
echo "==> Ad-hoc signing"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=1 "$APP" 2>&1 | sed 's/^/    /' || true

echo ""
echo "✅ Built $APP"
echo "   Launch it:  open \"$APP\""
echo "   For lid-closed-on-battery to actually work, run ./install.sh once to add the"
echo "   passwordless grant (it explains exactly what it installs)."
