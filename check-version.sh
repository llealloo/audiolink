#!/usr/bin/env sh
#
# Checks the version agrees in every place CONTRIBUTING.MD lists.

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
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$1" | head -1
}

version=$(json_version "$PKG/package.json")

if [ -z "$version" ]; then
    echo "error: could not read a version from $PKG/package.json" >&2
    exit 1
fi

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

# X.Y.Z: Major is X.00f, Minor is Y.0Zf.
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
