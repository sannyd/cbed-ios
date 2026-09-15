#!/bin/bash
#
# build_and_upload.sh — Build, archive, export, and upload CBED to App Store Connect
#
# Requirements:
#   - Xcode installed (tested with Xcode 15.x)
#   - Logged in to Apple ID in Xcode → Settings → Accounts
#   - Pods installed (run `pod install` once)
#   - This script is run from the project root (where CBED.xcworkspace lives)
#
# Usage:
#   ./build_and_upload.sh         # full pipeline: archive → export → upload
#   ./build_and_upload.sh archive # just archive
#   ./build_and_upload.sh export  # just export the latest archive
#   ./build_and_upload.sh upload  # just upload the exported .ipa
#
set -euo pipefail

ACTION="${1:-all}"

PROJECT_DIR="$(pwd)"
WORKSPACE="$PROJECT_DIR/CBED.xcworkspace"
SCHEME="CBED"
EXPORT_OPTIONS="$PROJECT_DIR/CBED/ExportOptions-AppStore.plist"
ARCHIVE_PATH="$PROJECT_DIR/build/CBED.xcarchive"
EXPORT_PATH="$PROJECT_DIR/build/export"
IPA_PATH="$EXPORT_PATH/CBED.ipa"

mkdir -p "$PROJECT_DIR/build"

# Sanity checks
if [ ! -d "$WORKSPACE" ]; then
  echo "ERROR: $WORKSPACE not found. Run this from the project root." >&2
  exit 1
fi
if [ ! -f "$EXPORT_OPTIONS" ]; then
  echo "ERROR: $EXPORT_OPTIONS not found." >&2
  exit 1
fi

verify_xcode() {
  XCODE_PATH=$(xcode-select -p)
  if [[ "$XCODE_PATH" == *CommandLineTools* ]]; then
    echo "ERROR: xcode-select is pointed at CommandLineTools, not Xcode." >&2
    echo "Fix: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer" >&2
    exit 1
  fi
  echo "✓ Xcode: $XCODE_PATH"
}

archive() {
  verify_xcode
  echo "==> Cleaning..."
  xcodebuild clean -workspace "$WORKSPACE" -scheme "$SCHEME" -configuration Release -quiet

  echo "==> Building pods..."
  # pod install is idempotent
  if command -v pod >/dev/null 2>&1; then
    pod install --silent || true
  fi

  echo "==> Archiving..."
  xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM=5KQUA2VRMH \
    | xcpretty || xcodebuild archive \
      -workspace "$WORKSPACE" \
      -scheme "$SCHEME" \
      -configuration Release \
      -destination "generic/platform=iOS" \
      -archivePath "$ARCHIVE_PATH" \
      CODE_SIGN_STYLE=Automatic \
      DEVELOPMENT_TEAM=5KQUA2VRMH
  echo "✓ Archive created: $ARCHIVE_PATH"
}

export_ipa() {
  if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "ERROR: archive not found at $ARCHIVE_PATH. Run 'archive' first." >&2
    exit 1
  fi
  echo "==> Exporting IPA..."
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$EXPORT_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS"
  echo "✓ Exported: $IPA_PATH"
}

upload() {
  if [ ! -f "$IPA_PATH" ]; then
    echo "ERROR: IPA not found at $IPA_PATH. Run 'export' first." >&2
    exit 1
  fi
  echo "==> Uploading to App Store Connect..."
  if command -v xcrun >/dev/null 2>&1; then
    xcrun altool --upload-app \
      --type ios \
      --file "$IPA_PATH" \
      --username "sanny.do@gmail.com" \
      --password "@keychain:AC_PASSWORD" \
      --verbose || {
        echo "altool failed — try Transporter or Xcode → Organizer → Distribute App"
        exit 1
      }
  else
    echo "xcrun not available — use Xcode Organizer or Transporter to upload:"
    echo "  $IPA_PATH"
  fi
  echo "✓ Upload started. Check App Store Connect in 5-15 minutes."
}

case "$ACTION" in
  archive) archive ;;
  export)  export_ipa ;;
  upload)  upload ;;
  all)
    archive
    export_ipa
    upload
    ;;
  *)
    echo "Usage: $0 [all|archive|export|upload]" >&2
    exit 1
    ;;
esac
