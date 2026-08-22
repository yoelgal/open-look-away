#!/usr/bin/env bash
# Assemble dist/Open Look Away.app from the Xcode project.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

die() { echo "build-app: $*" >&2; exit 1; }

VERSION="${OLA_VERSION:-}"
if [ -z "$VERSION" ]; then
    VERSION="$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)"
    VERSION="${VERSION#v}"
fi
[ -n "$VERSION" ] || VERSION="0.0.0"

DD="$ROOT/.build/dd"
DEST="$ROOT/dist/Open Look Away.app"
mkdir -p "$ROOT/dist" "$DD"

echo "==> building $VERSION"
xcodebuild \
    -project app/OpenLookAway.xcodeproj \
    -scheme OpenLookAway \
    -configuration Release \
    -derivedDataPath "$DD" \
    -destination 'platform=macOS' \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION=1 \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=YES \
    build

BUILT="$DD/Build/Products/Release/OpenLookAway.app"
[ -d "$BUILT" ] || die "xcodebuild did not produce $BUILT"

rm -rf "$DEST"
ditto "$BUILT" "$DEST"

# Display name with spaces; the product name stays OpenLookAway for the executable.
/usr/libexec/PlistBuddy -c "Set :CFBundleName Open Look Away" "$DEST/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleName string Open Look Away" "$DEST/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Open Look Away" "$DEST/Contents/Info.plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string Open Look Away" "$DEST/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$DEST/Contents/Info.plist"

codesign --force --deep --sign - "$DEST" || die "codesign failed"

echo "    $DEST"
