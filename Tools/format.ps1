# Applies the .editorconfig whitespace rules to the package.
#
#   .\Tools\format.ps1          rewrite in place
#   .\Tools\format.ps1 -Check   report only, non-zero exit

param(
    [switch]$Check,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$DotnetArgs
)

Set-Location (Join-Path $PSScriptRoot '..')

$FormatPaths = @('Packages/com.llealloo.audiolink')

if ($null -eq (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    [Console]::Error.WriteLine('error: dotnet not found on PATH.')
    [Console]::Error.WriteLine('       install the .NET SDK from https://dotnet.microsoft.com/download')
    exit 1
}

if (-not (dotnet --list-sdks 2> $null)) {
    [Console]::Error.WriteLine('error: a .NET runtime is installed but no SDK, so dotnet format is unavailable.')
    [Console]::Error.WriteLine('       install the .NET SDK from https://dotnet.microsoft.com/download')
    exit 1
}

$ArgList = @()
if ($Check) {
    $ArgList += '--verify-no-changes'
}
if ($DotnetArgs) {
    $ArgList += $DotnetArgs
}

$Utf8 = New-Object System.Text.UTF8Encoding($false)
$Bom = [byte[]](0xEF, 0xBB, 0xBF)
$TrailingWhitespace = New-Object System.Text.RegularExpressions.Regex('[ \t]+(\r?)$', 'Multiline')

# dotnet format misses trailing whitespace on comments and across #if, and
# never adds a final newline. Works on bytes to keep BOMs and CRLF intact.
function Invoke-Tidy($Path) {
    $found = $false

    foreach ($file in Get-ChildItem -Path $Path -Recurse -File -Filter '*.cs') {
        $bytes = [System.IO.File]::ReadAllBytes($file.FullName)

        $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        $offset = 0
        if ($hasBom) {
            $offset = 3
        }

        $text = $Utf8.GetString($bytes, $offset, $bytes.Length - $offset)
        $tidied = $TrailingWhitespace.Replace($text, '$1')
        if ($tidied.Length -gt 0 -and -not $tidied.EndsWith("`n")) {
            $tidied += "`n"
        }

        if ($tidied -ceq $text) {
            continue
        }

        if ($Check) {
            $relative = Resolve-Path -Relative $file.FullName
            [Console]::Error.WriteLine("${relative}: trailing whitespace or missing final newline")
            $found = $true
            continue
        }

        $out = $Utf8.GetBytes($tidied)
        if ($hasBom) {
            $out = $Bom + $out
        }
        [System.IO.File]::WriteAllBytes($file.FullName, [byte[]]$out)
    }

    return $found
}

$status = 0
foreach ($path in $FormatPaths) {
    "==> $path"
    & dotnet format whitespace $path --folder @ArgList
    if ($LASTEXITCODE -ne 0) {
        $status = $LASTEXITCODE
    }
    if (Invoke-Tidy $path) {
        $status = 1
    }
}

exit $status
