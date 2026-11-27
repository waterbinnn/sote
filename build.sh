#!/bin/sh
# Sote.app 을 만든다. 사용법: ./build.sh && open Sote.app
set -e
cd "$(dirname "$0")"
swift build -c release
APP=Sote.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Sote "$APP/Contents/MacOS/"

# 앱 아이콘: 코드로 그린 1024px 원본을 크기별로 줄여 .icns 로 묶는다.
ICONSET=.build/AppIcon.iconset
rm -rf "$ICONSET" && mkdir -p "$ICONSET"
.build/release/Sote --icon "$ICONSET/icon_512x512@2x.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  [ $s -lt 512 ] && sips -z $((s*2)) $((s*2)) "$ICONSET/icon_512x512@2x.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Sote</string>
  <key>CFBundleDisplayName</key><string>Sote</string>
  <key>CFBundleExecutable</key><string>Sote</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleIdentifier</key><string>app.sote.note</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleDevelopmentRegion</key><string>ko</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force -s - "$APP"
echo "built $APP"
