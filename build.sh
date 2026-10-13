#!/bin/bash
# Builds ScreenBuddy.app (ad-hoc signed). Pass "install" to copy it to ~/Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/ScreenBuddy.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/ScreenBuddy "$APP/Contents/MacOS/"
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
