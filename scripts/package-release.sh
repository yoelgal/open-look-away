#!/usr/bin/env bash
#
# Packages dist/OpenLookAway.app into the two files a GitHub release carries.
#
#   scripts/build-app.sh && scripts/package-release.sh
#
# Writes dist/OpenLookAway-arm64.zip and dist/OpenLookAway-arm64.zip.sha256.
# The asset names carry no version so releases/latest/download/<name> stays stable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/dist/OpenLookAway.app"
ZIP="$ROOT/dist/OpenLookAway-arm64.zip"
DIGEST="$ZIP.sha256"

die() { echo "package-release: $*" >&2; exit 1; }

[ -d "$APP" ] || die "there is no $APP to package. Run scripts/build-app.sh first."

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "$APP/Contents/Info.plist" 2>/dev/null || true)"
[ -n "$VERSION" ] || die "$APP has no CFBundleShortVersionString."

echo "==> packaging $VERSION"
rm -f "$ZIP" "$DIGEST"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP" || die "ditto could not archive $APP"
( cd "$(dirname "$ZIP")" && shasum -a 256 "$(basename "$ZIP")" ) > "$DIGEST"

CHECK="$(mktemp -d)"
trap 'rm -rf "$CHECK"' EXIT
ditto -x -k "$ZIP" "$CHECK" || die "the zip just written does not extract"
[ -d "$CHECK/OpenLookAway.app" ] || die "the zip does not contain OpenLookAway.app at its root"
codesign --verify --strict "$CHECK/OpenLookAway.app" \
    || die "the extracted bundle fails codesign. Do not ship this."

echo "    version   $VERSION"
echo "    digest    $(cut -d' ' -f1 "$DIGEST")"
echo "$ZIP"
