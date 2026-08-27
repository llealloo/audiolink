#!/usr/bin/env sh
#
# Applies the .editorconfig whitespace rules to the package.
#
#   ./format.sh           rewrite in place
#   ./format.sh --check   report only, non-zero exit

set -eu

CHECK=0

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

if ! command -v perl > /dev/null 2>&1; then
    echo "error: perl not found on PATH, needed for the trailing whitespace pass." >&2
    exit 1
fi

ARGS=""
for arg in "$@"; do
    case "$arg" in
        --check)
            CHECK=1
            ARGS="$ARGS --verify-no-changes"
            ;;
        *) ARGS="$ARGS $arg" ;;
    esac
done

# dotnet format misses trailing whitespace on comments and across #if, and
# never adds a final newline.
tidy() {
    tidy_path="$1"
    tidy_found=0

    while IFS= read -r file; do
        tmp="$file.format-tmp"

        # Not sed: Git Bash sed turns CRLF into LF.
        perl -pe 's/[ \t]+(\r?)$/$1/' "$file" > "$tmp"
        if [ -s "$tmp" ] && [ -n "$(tail -c 1 "$tmp")" ]; then
            printf '\n' >> "$tmp"
        fi

        if cmp -s "$file" "$tmp"; then
            rm -f "$tmp"
        elif [ "$CHECK" -eq 1 ]; then
            rm -f "$tmp"
            echo "$file: trailing whitespace or missing final newline" >&2
            tidy_found=1
        else
            cat "$tmp" > "$file"
            rm -f "$tmp"
        fi
    done <<EOF
$(find "$tidy_path" -type f -name '*.cs')
EOF

    return $tidy_found
}

status=0
for path in $FORMAT_PATHS; do
    echo "==> $path"
    # shellcheck disable=SC2086
    dotnet format whitespace "$path" --folder $ARGS || status=$?
    tidy "$path" || status=1
done

exit $status
