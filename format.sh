#!/usr/bin/env sh
#
# Applies the .editorconfig whitespace rules to the package.
#
#   ./format.sh           rewrite in place
#   ./format.sh --check   report only, non-zero exit

set -eu

cd "$(dirname "$0")"

FORMAT_PATHS="Packages/com.llealloo.audiolink"

if ! command -v dotnet > /dev/null 2>&1; then
    echo "error: dotnet not found on PATH." >&2
    echo "       install the .NET SDK from https://dotnet.microsoft.com/download" >&2
    exit 1
fi

if [ -z "$(dotnet --list-sdks 2> /dev/null)" ]; then
    echo "error: a .NET runtime is installed but no SDK, so dotnet format is unavailable." >&2
    echo "       install the .NET SDK from https://dotnet.microsoft.com/download" >&2
    exit 1
fi

ARGS=""
for arg in "$@"; do
    case "$arg" in
        --check) ARGS="$ARGS --verify-no-changes" ;;
        *) ARGS="$ARGS $arg" ;;
    esac
done

status=0
for path in $FORMAT_PATHS; do
    echo "==> $path"
    # shellcheck disable=SC2086
    dotnet format whitespace "$path" --folder $ARGS || status=$?
done

exit $status
