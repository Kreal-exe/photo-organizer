#!/bin/bash
# Builds Photo Organizer for macOS with the Xcode Command Line Tools — no Xcode project needed.
#
#   ./build.sh          build and install /Applications/PhotoOrganizer.app (Apple Silicon + Intel)
#   ./build.sh run      the same, then open it
#   ./build.sh test     build and run the core tests
#   ./build.sh zip      build build/PhotoOrganizer-macOS-$VERSION.zip (the release workflow uses it)
#
# The app is put straight into Applications, not into the project folder: the project lives in iCloud Drive, which
# would sync the app's bundle as a pile of folders, and its file attributes keep codesign from signing there.
set -euo pipefail
cd "$(dirname "$0")"

VERSION="${VERSION:-$(tr -d '[:space:]' < VERSION)}"
APPLICATIONS="/Applications"
[ -w "$APPLICATIONS" ] || APPLICATIONS="$HOME/Applications"
INSTALLED="$APPLICATIONS/PhotoOrganizer.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
APP="$WORK/PhotoOrganizer.app"

CFLAGS=(-fobjc-arc -O2 -Wall -Wno-unused-parameter -mmacosx-version-min=12.0)
FRAMEWORKS=(Cocoa Quartz QuickLookThumbnailing UniformTypeIdentifiers ImageIO AVFoundation AVKit CoreMedia
            Vision CoreML Accelerate WebKit MapKit CoreLocation)
# The parts the tests exercise, which need no window server.
CORE=(POPhotoItem POScanner POPlan POOrganizer POStrings POSimilarCopies POVKAlbum POManualDates PODateSuggestions POPictureText POScreenshots POMediaTypes)

frameworks() {
    for framework in "$@"; do printf -- '-framework %s ' "$framework"; done
}

build() {
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
    echo "Compiling…"
    # shellcheck disable=SC2046
    clang "${CFLAGS[@]}" -arch arm64 -arch x86_64 $(frameworks "${FRAMEWORKS[@]}") Sources/*.m -o "$APP/Contents/MacOS/PhotoOrganizer"
    cp Resources/Info.plist "$APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD_NUMBER:-$VERSION}" "$APP/Contents/Info.plist"
    printf 'APPL????' > "$APP/Contents/PkgInfo"
    cp Resources/AppIcon.icns Resources/vit_mlx.py "$APP/Contents/Resources/"
    cp -R Resources/*.lproj "$APP/Contents/Resources/"
    # Files copied out of iCloud Drive carry its attributes, which codesign refuses.
    xattr -cr "$APP"
    codesign --force --sign - "$APP"
}

install_app() {
    build
    mkdir -p "$APPLICATIONS"
    rm -rf "$INSTALLED"
    ditto "$APP" "$INSTALLED"
    echo "Installed $INSTALLED ($VERSION)"
}

case "${1:-build}" in
    build) install_app ;;
    run)   install_app && open "$INSTALLED" ;;
    test)
        # shellcheck disable=SC2046
        clang "${CFLAGS[@]}" -ISources $(frameworks Foundation ImageIO CoreGraphics CoreText UniformTypeIdentifiers AVFoundation CoreMedia CoreVideo Vision) \
            $(printf 'Sources/%s.m ' "${CORE[@]}") Tests/CoreTests.m -o "$WORK/core-tests"
        "$WORK/core-tests" ;;
    zip)
        build
        mkdir -p build
        ditto -c -k --keepParent "$APP" "build/PhotoOrganizer-macOS-$VERSION.zip"
        echo "Packed build/PhotoOrganizer-macOS-$VERSION.zip" ;;
    *)     sed -n '2,7p' "$0"; exit 1 ;;
esac
