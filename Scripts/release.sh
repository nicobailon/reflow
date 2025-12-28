#!/bin/bash
set -e

VERSION="${1:-0.1.0}"
PRODUCT_NAME="Reflow"
BUILD_DIR=".build/release"
ARCHIVE_DIR="archives"
DMG_NAME="${PRODUCT_NAME}-${VERSION}.dmg"

echo "Building ${PRODUCT_NAME} v${VERSION}..."

swift build -c release --product Reflow

mkdir -p "${ARCHIVE_DIR}"

APP_PATH="${BUILD_DIR}/${PRODUCT_NAME}.app"
if [ -d "${APP_PATH}" ]; then
    echo "Creating DMG..."
    
    hdiutil create -volname "${PRODUCT_NAME}" \
        -srcfolder "${APP_PATH}" \
        -ov -format UDZO \
        "${ARCHIVE_DIR}/${DMG_NAME}"
    
    echo "Created ${ARCHIVE_DIR}/${DMG_NAME}"
else
    echo "Note: No .app bundle found (SPM build produces executable only)"
    echo "Executable at: ${BUILD_DIR}/Reflow"
    
    cp "${BUILD_DIR}/Reflow" "${ARCHIVE_DIR}/${PRODUCT_NAME}-${VERSION}"
    echo "Copied executable to ${ARCHIVE_DIR}/${PRODUCT_NAME}-${VERSION}"
fi

if [ -n "${SIGN_IDENTITY}" ]; then
    echo "Signing..."
    codesign --force --sign "${SIGN_IDENTITY}" \
        --options runtime \
        --entitlements "Sources/Reflow/Resources/Reflow.entitlements" \
        "${BUILD_DIR}/Reflow"
    
    echo "Notarizing..."
    xcrun notarytool submit "${ARCHIVE_DIR}/${DMG_NAME}" \
        --keychain-profile "notarytool" \
        --wait
    
    echo "Stapling..."
    xcrun stapler staple "${ARCHIVE_DIR}/${DMG_NAME}"
fi

echo "Done!"
echo ""
echo "Release artifacts in ${ARCHIVE_DIR}/"
ls -la "${ARCHIVE_DIR}/"

if [ -f "${ARCHIVE_DIR}/${DMG_NAME}" ]; then
    SHA256=$(shasum -a 256 "${ARCHIVE_DIR}/${DMG_NAME}" | awk '{print $1}')
    echo ""
    echo "SHA256: ${SHA256}"
    echo ""
    echo "Update reflow.rb with:"
    echo "  sha256 \"${SHA256}\""
fi
