#!/usr/bin/env sh
#
# Asserts that the version number agrees in every place CONTRIBUTING.MD lists.
#
#   ./check-version.sh
#
# Releasing means six hand edits in six unrelated files and nothing has ever
# checked that they landed. This does. It takes the version in package.json as
# the source of truth and compares everything else against it.

set -eu

cd "$(dirname "$0")"

PKG="Packages/com.llealloo.audiolink"

fail=0

check() {
    name="$1"
    expected="$2"
    actual="$3"
    if [ "$expected" = "$actual" ]; then
        printf '  ok    %-28s %s\n' "$name" "$actual"
    else
        printf '  FAIL  %-28s %s (expected %s)\n' "$name" "$actual" "$expected"
        fail=1
    fi
}

json_version() {
    # matches `"version" : "3.1.2"` with any spacing around the colon
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

version=$(json_version "$PKG/package.json")

if [ -z "$version" ]; then
    echo "error: could not read a version from $PKG/package.json" >&2
    exit 1
fi

# Split X.Y.Z so we can rebuild the two floats in AudioLink.cs.
major=${version%%.*}
rest=${version#*.}
minor=${rest%%.*}
patch=${rest##*.}

case "$version" in
    "$major.$minor.$patch") ;;
    *)
        echo "error: '$version' is not a three part X.Y.Z version" >&2
        exit 1
        ;;
esac

echo "version from $PKG/package.json: $version"
echo

check "StandaloneMetadata pkg" "$version" \
    "$(json_version .github/workflows/StandaloneMetadata/package.json)"

check "VERSION.txt" "$version" \
    "$(tr -d ' \t\r\n' < "$PKG/Runtime/VERSION.txt")"

check "CHANGELOG.md heading" "$version" \
    "$(sed -n 's/^## \([0-9][0-9.]*\).*/\1/p' CHANGELOG.md | head -1)"

check "AudioLinkAssetManager.cs" "$version" \
    "$(sed -n 's|.*baseAssetsPath = "Samples/AudioLink/\([^"]*\)".*|\1|p' \
        "$PKG/Editor/Scripts/AudioLinkAssetManager.cs" | head -1)"

# Convention: for X.Y.Z, Major is X.00f and Minor is Y.0Zf. See CONTRIBUTING.MD.
al_cs="$PKG/Runtime/Scripts/AudioLink.cs"

check "AudioLinkVersionNumberMajor" \
    "$(printf '%d.%02d' "$major" 0)" \
    "$(sed -n 's/.*AudioLinkVersionNumberMajor[[:space:]]*=[[:space:]]*\([0-9.]*\)f.*/\1/p' "$al_cs" | head -1)"

check "AudioLinkVersionNumberMinor" \
    "$(printf '%d.%02d' "$minor" "$patch")" \
    "$(sed -n 's/.*AudioLinkVersionNumberMinor[[:space:]]*=[[:space:]]*\([0-9.]*\)f.*/\1/p' "$al_cs" | head -1)"

echo
if [ "$fail" -ne 0 ]; then
    echo "Version numbers disagree. See the release checklist in CONTRIBUTING.MD."
    exit 1
fi

echo "All version numbers agree."
