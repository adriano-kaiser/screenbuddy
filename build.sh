#!/bin/bash
# Builds ScreenBuddy.app (ad-hoc signed). Pass "install" to copy it to ~/Applications and launch it.
# Set UNIVERSAL=1 for an arm64 + x86_64 binary (needs full Xcode; used by CI).
set -euo pipefail
cd "$(dirname "$0")"

ARCH_FLAGS=()
if [[ "${UNIVERSAL:-}" == 1 ]]; then
    ARCH_FLAGS=(--arch arm64 --arch x86_64)
fi
swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"}
BIN_DIR="$(swift build -c release ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} --show-bin-path)"

APP=build/ScreenBuddy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/ScreenBuddy" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
codesign --force --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x ScreenBuddy || true
    mkdir -p ~/Applications
    rm -rf ~/Applications/ScreenBuddy.app
    cp -R "$APP" ~/Applications/
    open ~/Applications/ScreenBuddy.app
    echo "Installed to ~/Applications/ScreenBuddy.app"
fi
