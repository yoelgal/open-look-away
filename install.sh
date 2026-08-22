#!/bin/bash
#
# OpenLookAway — one-command install.
#
#   curl -fsSL https://raw.githubusercontent.com/yoelgal/open-look-away/main/install.sh | bash
#
# Downloads the current release, checks it against its published checksum, installs the app,
# and opens it. Safe to re-run: it upgrades in place.
#
#   install.sh --from-source     clone and build here instead. Needs Xcode / CLT.
#
# Written to survive being piped into bash. Under a pipe stdin is the script, so prompts
# read from /dev/tty.
#
# Overrides, all optional:
#   OLA_ASSET_URL=url     download this instead of the GitHub release (file:// works)
#   OLA_ASSET_SHA256=hex  the expected digest, instead of fetching <asset-url>.sha256
#   OLA_VERSION=v1.0.0    install this release rather than the latest
#   OLA_APPS=/path        where the .app goes                (default /Applications)
#   OLA_SRC=/path         where --from-source clones to      (default ./open-look-away)
#   OLA_NO_OPEN=1         install, do not launch
#
# On the piped command they go on `bash`, on the right of the pipe:
#
#   curl -fsSL …/install.sh | OLA_VERSION=v1.0.0 bash
set -euo pipefail

APPS="${OLA_APPS:-/Applications}"
REPO="https://github.com/yoelgal/open-look-away.git"
RELEASES="https://github.com/yoelgal/open-look-away/releases"
ASSET="OpenLookAway-arm64.zip"
APP_NAME="OpenLookAway.app"
BUNDLE_ID="dev.openlookaway.app"

say()  { printf '\033[1m==>\033[0m %s\n' "$1"; }
die()  { printf '\033[1;31mopen-look-away:\033[0m %s\n' "$1" >&2; exit 1; }

SELF="${BASH_SOURCE[0]:-}"
[ -n "$SELF" ] && [ -f "$SELF" ] || SELF=""

usage() {
    if [ -n "$SELF" ]; then
        awk 'NR == 1 { next } /^#/ { print substr($0, 3); next } { exit }' "$SELF"
    else
        echo "OpenLookAway installer. Downloads the current release and installs it."
        echo "    --from-source   clone and build from source instead"
        echo "Every option: https://github.com/yoelgal/open-look-away/blob/main/install.sh"
    fi
}

FROM_SOURCE=0
for arg in "$@"; do
    case "$arg" in
        --from-source) FROM_SOURCE=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "install: unknown argument: $arg" >&2; exit 64 ;;
    esac
done

[ "$(uname -s)" = "Darwin" ] || die "OpenLookAway is macOS only."
major=$(sw_vers -productVersion | cut -d. -f1)
[ "$major" -ge 13 ] || die "Needs macOS 13 or later; this is $(sw_vers -productVersion)."
[ "$(uname -m)" = "arm64" ] || die "There is no Intel build. This Mac is $(uname -m)."

can_replace() {
    [ -w "$(dirname "$1")" ] && return 0
    case " $(id -Gn 2>/dev/null) " in *" admin "*) ;; *) return 1 ;; esac
    ( exec 3</dev/tty ) 2>/dev/null || return 1
    return 0
}

STRANDED=""
if [ -z "${OLA_APPS:-}" ] && [ ! -w "$APPS" ]; then
    if [ -e "$APPS/$APP_NAME" ] && can_replace "$APPS/$APP_NAME"; then
        say "$APPS needs an administrator, and OpenLookAway is already installed there, so this upgrades
    that copy rather than leaving it behind. macOS will ask for your password."
    else
        [ -e "$APPS/$APP_NAME" ] && STRANDED="$APPS/$APP_NAME"
        APPS="$HOME/Applications"
        if [ -n "$STRANDED" ]; then
            say "$STRANDED needs an administrator to replace, so the new version is going to $APPS instead."
        else
            say "/Applications needs an administrator, so the app is going to $APPS instead."
        fi
    fi
fi

LOCK=""
LOCK_HOME="$HOME/Library/Caches/$BUNDLE_ID"
LOCK_DIR="$LOCK_HOME/install.lock"
mkdir -p "$LOCK_HOME" 2>/dev/null || true
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    HOLDER="$(cat "$LOCK_DIR/pid" 2>/dev/null || true)"
    case "$HOLDER" in
        ''|*[!0-9]*) HOLDER="" ;;
        *) [ "$HOLDER" -ge 2 ] 2>/dev/null || HOLDER="" ;;
    esac
    if [ -n "$HOLDER" ] && kill -0 "$HOLDER" 2>/dev/null; then
        die "Another OpenLookAway install is running (process $HOLDER). Wait for that one to finish."
    fi
    rm -rf "$LOCK_DIR" 2>/dev/null || true
    mkdir "$LOCK_DIR" 2>/dev/null \
        || die "Could not take the install lock at $LOCK_DIR. Remove that directory and run this again."
fi
LOCK="$LOCK_DIR"
printf '%s\n' "$$" > "$LOCK_DIR/pid" 2>/dev/null || true

WORK=""
OLD_BUNDLE=""
STAGED=""

cleanup() {
    status=$?
    if [ -n "${OLD_BUNDLE:-}" ] && [ -d "$OLD_BUNDLE" ]; then
        if [ ! -d "$APPS/$APP_NAME" ]; then
            mv "$OLD_BUNDLE" "$APPS/$APP_NAME" 2>/dev/null || true
        else
            rm -rf "$OLD_BUNDLE" 2>/dev/null || true
        fi
    fi
    [ -n "${WORK:-}" ] && [ -d "$WORK" ] && rm -rf "$WORK"
    [ -n "${LOCK:-}" ] && [ -d "$LOCK" ] && rm -rf "$LOCK"
    exit "$status"
}
trap cleanup EXIT

ask() {
    printf '    %s [Y/n] ' "$1"
    if ! read -r reply 2>/dev/null < /dev/tty; then echo "(no terminal to ask on)"; return 1; fi
    case "$reply" in [nN]*) return 1 ;; *) return 0 ;; esac
}

build_from_source() {
    if [ -n "$SELF" ] && [ -f "$(dirname "$SELF")/app/OpenLookAway.xcodeproj/project.pbxproj" ]; then
        cd "$(dirname "$SELF")"
    else
        SRC="${OLA_SRC:-$PWD/open-look-away}"
        if [ -d "$SRC/.git" ]; then
            say "Updating $SRC"
            git -C "$SRC" pull --ff-only --quiet
        else
            say "Cloning into $SRC"
            git clone --quiet "$REPO" "$SRC" || die "Clone failed. Check your network, or clone by hand:
    git clone $REPO"
        fi
        cd "$SRC"
    fi
    command -v xcodebuild >/dev/null || die "Building from source needs Xcode or the Command Line Tools.
    Install them with:  xcode-select --install"
    say "Building"
    bash scripts/build-app.sh
    STAGED="$PWD/dist/OpenLookAway.app"
}

download_release() {
    if [ -n "${OLA_ASSET_URL:-}" ]; then
        URL="$OLA_ASSET_URL"
    elif [ -n "${OLA_VERSION:-}" ]; then
        URL="$RELEASES/download/$OLA_VERSION/$ASSET"
    else
        URL="$RELEASES/latest/download/$ASSET"
    fi

    PROTO="--proto =https --proto-redir =https"
    case "$URL" in
        file://*) PROTO="--proto =file" ;;
    esac

    WORK="$(mktemp -d)"

    if [ -n "${OLA_ASSET_URL:-}" ]; then
        say "Downloading $URL"
    else
        say "Downloading ${OLA_VERSION:-the latest release}"
    fi
    curl -fL $PROTO --retry 3 --progress-bar -o "$WORK/$ASSET" "$URL" \
        || die "Could not download $URL
    Check your network, or download the zip from $RELEASES/latest and unzip it into /Applications."

    EXPECTED="${OLA_ASSET_SHA256:-}"
    DIGEST_FROM="OLA_ASSET_SHA256"
    if [ -z "$EXPECTED" ]; then
        DIGEST_FROM="$URL.sha256"
        curl -fsSL $PROTO --retry 3 -o "$WORK/$ASSET.sha256" "$DIGEST_FROM" \
            || die "The download has no published checksum at $DIGEST_FROM, so there is nothing to
    check it against. Refusing to install an app this script cannot verify."
        EXPECTED="$(cut -d' ' -f1 < "$WORK/$ASSET.sha256")"
    fi
    if [ "${#EXPECTED}" -ne 64 ] || [ -n "$(printf '%s' "$EXPECTED" | tr -d '0-9a-f')" ]; then
        die "The checksum from $DIGEST_FROM is not a SHA-256 digest:
    $EXPECTED"
    fi

    say "Checking it against the checksum from $DIGEST_FROM"
    ( cd "$WORK" && printf '%s  %s\n' "$EXPECTED" "$ASSET" | shasum -a 256 -c --status - ) \
        || die "The download does not match the checksum from $DIGEST_FROM.

    Expected $EXPECTED
    Got      $(shasum -a 256 "$WORK/$ASSET" | cut -d' ' -f1)

    Nothing has been installed or removed."

    ditto -x -k "$WORK/$ASSET" "$WORK/unpacked" || die "The download will not unpack."
    STAGED="$WORK/unpacked/$APP_NAME"
    [ -d "$STAGED" ] || die "There is no $APP_NAME inside $ASSET."

    codesign --verify --strict "$STAGED" \
        || die "The downloaded app's code signature does not verify. Nothing has been installed."
}

if [ "$FROM_SOURCE" = 1 ]; then
    build_from_source
else
    download_release
fi

mkdir -p "$APPS" || die "Could not create $APPS. Point OLA_APPS at somewhere writable."

EXEC_PATH="$APPS/$APP_NAME/Contents/MacOS/OpenLookAway"

if [ -d "$APPS/$APP_NAME" ]; then
    say "Replacing $APPS/$APP_NAME"
    if pgrep -f "/$APP_NAME/Contents/MacOS/OpenLookAway$" >/dev/null 2>&1; then
        say "Waiting for the running app to quit"
        pkill -f "/$APP_NAME/Contents/MacOS/OpenLookAway$" 2>/dev/null || true
        for _ in $(seq 40); do
            pgrep -f "/$APP_NAME/Contents/MacOS/OpenLookAway$" >/dev/null 2>&1 || break
            sleep 0.25
        done
        if pgrep -f "/$APP_NAME/Contents/MacOS/OpenLookAway$" >/dev/null 2>&1; then
            die "OpenLookAway is still running. Quit it from the menu extra, then run this again."
        fi
    fi
    OLD_BUNDLE="$APPS/$APP_NAME.replaced-$$"
    mv "$APPS/$APP_NAME" "$OLD_BUNDLE" 2>/dev/null || {
        say "Replacing $APPS/$APP_NAME needs an administrator; macOS will ask for your password"
        sudo mv "$APPS/$APP_NAME" "$OLD_BUNDLE" < /dev/tty \
            || die "Could not move $APPS/$APP_NAME out of the way, so nothing has been changed."
    }
fi

say "Installing to $APPS"
[ ! -e "$APPS/$APP_NAME" ] || die "Something put an app back at $APPS/$APP_NAME while this
    install was running. Nothing has been changed; run this again."
mv "$STAGED" "$APPS/$APP_NAME" 2>/dev/null || {
    say "$APPS needs an administrator; you will be asked for your password"
    sudo mv "$STAGED" "$APPS/$APP_NAME" < /dev/tty \
        || die "Could not install into $APPS. The app that was there has been put back.
    OLA_APPS=\$HOME/Applications installs without a password."
}

echo
say "Installed."
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
    "$APPS/$APP_NAME/Contents/Info.plist" 2>/dev/null || true)"
echo "    $APP_NAME   $APPS/$APP_NAME${VERSION:+  (version $VERSION)}"
if [ -n "$STRANDED" ]; then
    echo
    echo "    An older copy is still at $STRANDED."
    printf '      sudo rm -rf "%s"\n' "$STRANDED"
fi
echo

[ "${OLA_NO_OPEN:-}" = "1" ] || open "$APPS/$APP_NAME"
