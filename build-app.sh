#!/bin/bash
# Compile PressePapiers et crée build/PressePapiers.app
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/PressePapiers"

APP="build/PressePapiers.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/PressePapiers"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>PressePapiers</string>
    <key>CFBundleDisplayName</key><string>PressePapiers</string>
    <key>CFBundleIdentifier</key><string>local.thomas.pressepapiers</string>
    <key>CFBundleExecutable</key><string>PressePapiers</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

# Signature locale (ad hoc), suffisante pour un usage personnel.
codesign --force --sign - "$APP"

echo ""
echo "✅ App créée : $(pwd)/$APP"
echo "   Pour l'installer : cp -R \"$APP\" /Applications/ && open /Applications/PressePapiers.app"
