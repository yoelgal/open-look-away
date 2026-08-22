#!/usr/bin/env bash
# Assemble dist/OpenLookAway.app from the Xcode project.
#
#   scripts/build-app.sh              # Release
#   scripts/build-app.sh debug        # Debug (scripts/dev.sh)
#
# Overrides:
#   OLA_VERSION=0.1.7
#   OLA_BUNDLE_ID=dev.openlookaway.app-dev
#   OLA_APP_NAME=open-lookaway-dev
#   OLA_SOURCE_ROOT=/path/to/repo     stamps Info.plist for SelfUpdate
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

die() { echo "build-app: $*" >&2; exit 1; }

CONFIG="Release"
case "${1:-}" in
    ""|release|Release) CONFIG="Release" ;;
    debug|Debug) CONFIG="Debug" ;;
    *) die "unknown config '$1' (use debug or release)" ;;
esac

VERSION="${OLA_VERSION:-}"
if [ -z "$VERSION" ]; then
    VERSION="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
    VERSION="${VERSION#v}"
fi
[ -n "$VERSION" ] || VERSION="0.0.0"

BUNDLE_ID="${OLA_BUNDLE_ID:-dev.openlookaway.app}"
APP_NAME="${OLA_APP_NAME:-OpenLookAway}"

DD="$ROOT/.build/dd"
DEST="$ROOT/dist/OpenLookAway.app"
mkdir -p "$ROOT/dist" "$DD"

echo "==> building $VERSION ($CONFIG) as $BUNDLE_ID"
xcodebuild \
    -project app/OpenLookAway.xcodeproj \
    -scheme OpenLookAway \
    -configuration "$CONFIG" \
    -derivedDataPath "$DD" \
    -destination 'platform=macOS' \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION=1 \
    PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    build

BUILT="$DD/Build/Products/$CONFIG/OpenLookAway.app"
[ -d "$BUILT" ] || die "xcodebuild did not produce $BUILT"

rm -rf "$DEST"
ditto "$BUILT" "$DEST"

plist="$DEST/Contents/Info.plist"
pb() {
    /usr/libexec/PlistBuddy -c "$1" "$plist" 2>/dev/null \
        || /usr/libexec/PlistBuddy -c "$2" "$plist"
}

pb "Set :CFBundleName $APP_NAME" "Add :CFBundleName string $APP_NAME"
pb "Set :CFBundleDisplayName $APP_NAME" "Add :CFBundleDisplayName string $APP_NAME"
pb "Set :CFBundleIdentifier $BUNDLE_ID" "Add :CFBundleIdentifier string $BUNDLE_ID"
pb "Set :CFBundleShortVersionString $VERSION" "Add :CFBundleShortVersionString string $VERSION"

if [ -n "${OLA_SOURCE_ROOT:-}" ]; then
    pb "Set :OLASourceRoot $OLA_SOURCE_ROOT" "Add :OLASourceRoot string $OLA_SOURCE_ROOT"
fi

codesign --force --deep --sign - "$DEST" || die "codesign failed"

echo "    $DEST"
