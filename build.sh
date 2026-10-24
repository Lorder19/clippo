#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release --arch arm64 --arch x86_64
APP=build/Clippo.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --arch arm64 --arch x86_64 --show-bin-path)/Clippo" "$APP/Contents/MacOS/Clippo"
cp Icon/Clippo.icns "$APP/Contents/Resources/Clippo.icns"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>app.clippo</string>
  <key>CFBundleName</key><string>Clippo</string>
  <key>CFBundleExecutable</key><string>Clippo</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>Clippo</string>
  <key>CFBundleShortVersionString</key><string>0.3.4</string>
  <key>CFBundleVersion</key><string>7</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleLocalizations</key><array><string>en</string><string>ru</string><string>zh-Hans</string></array>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 Clippo contributors. MIT License.</string>
</dict></plist>
PLIST
# A stable self-signed identity keeps the Accessibility grant across rebuilds; without one, sign ad-hoc
# (then macOS asks for Accessibility again after every build).
IDENTITY="Clipo Local Signing"
security find-identity -p codesigning | grep -q "\"$IDENTITY\"" || IDENTITY="-"
codesign --force --sign "$IDENTITY" --identifier app.clippo "$APP"

if [[ "${1:-}" == "install" ]]; then
  pkill -x Clippo || true
  pkill -x Clipo || true
  rm -rf /Applications/Clippo.app /Applications/Clipo.app # old name
  ditto "$APP" /Applications/Clippo.app
  open /Applications/Clippo.app
fi

if [[ "${1:-}" == "zip" ]]; then
  ditto -c -k --keepParent "$APP" build/Clippo.zip
  echo "build/Clippo.zip"
fi
