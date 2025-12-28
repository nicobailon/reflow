#!/bin/bash
set -e

VERSION="${1:-0.1.0}"
PRODUCT_NAME="Reflow"
BUILD_DIR=".build/release"
APP_BUNDLE="${BUILD_DIR}/${PRODUCT_NAME}.app"
ARCHIVE_DIR="archives"

echo "Building ${PRODUCT_NAME} v${VERSION}..."

swift build -c release --product Reflow

echo "Creating app bundle..."

rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"
mkdir -p "${APP_BUNDLE}/Contents/Frameworks"

cp "${BUILD_DIR}/Reflow" "${APP_BUNDLE}/Contents/MacOS/"

cat > "${APP_BUNDLE}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Reflow</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.nicobailon.Reflow</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Reflow</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>15.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2025. MIT License.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>SUFeedURL</key>
    <string>https://raw.githubusercontent.com/nicobailon/reflow/main/appcast.xml</string>
    <key>SUPublicEDKey</key>
    <string>PLACEHOLDER_ED25519_PUBLIC_KEY</string>
</dict>
</plist>
EOF

SPARKLE_PATH=$(find .build -name "Sparkle.framework" -type d 2>/dev/null | head -1)
if [ -n "${SPARKLE_PATH}" ]; then
    echo "Embedding Sparkle framework..."
    cp -R "${SPARKLE_PATH}" "${APP_BUNDLE}/Contents/Frameworks/"
fi

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
fi

mkdir -p "${ARCHIVE_DIR}"

ZIP_NAME="${PRODUCT_NAME}-${VERSION}.zip"
echo "Creating zip archive..."
ditto -c -k --keepParent "${APP_BUNDLE}" "${ARCHIVE_DIR}/${ZIP_NAME}"

echo ""
echo "Done! Release artifacts:"
ls -la "${ARCHIVE_DIR}/"

SHA256=$(shasum -a 256 "${ARCHIVE_DIR}/${ZIP_NAME}" | awk '{print $1}')
echo ""
echo "SHA256: ${SHA256}"
echo ""
echo "To install: unzip ${ARCHIVE_DIR}/${ZIP_NAME} and move Reflow.app to /Applications"
echo ""
echo "Note: This is an unsigned build. Users will need to:"
echo "  1. Right-click the app and select 'Open'"
echo "  2. Or: System Settings > Privacy & Security > Open Anyway"
