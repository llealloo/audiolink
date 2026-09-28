# Checks the version agrees in every place CONTRIBUTING.MD lists.

$ErrorActionPreference = 'Stop'

Set-Location (Join-Path $PSScriptRoot '..')

$Pkg = 'Packages/com.llealloo.audiolink'

$script:Failed = $false

function Test-Version($Name, $Expected, $Actual) {
    if ($Expected -eq $Actual) {
        '  ok    {0,-28} {1}' -f $Name, $Actual
    }
    else {
        '  FAIL  {0,-28} {1} (expected {2})' -f $Name, $Actual, $Expected
        $script:Failed = $true
    }
}

function Get-FirstMatch($Path, $Pattern) {
    $match = Select-String -Path $Path -Pattern $Pattern -CaseSensitive | Select-Object -First 1
    if ($null -eq $match) {
        return ''
    }
    return $match.Matches[0].Groups[1].Value
}

$JsonVersion = '"version"\s*:\s*"([^"]*)"'

$version = Get-FirstMatch "$Pkg/package.json" $JsonVersion

if ($version -eq '') {
    [Console]::Error.WriteLine("error: could not read a version from $Pkg/package.json")
    exit 1
}

if ($version -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
    [Console]::Error.WriteLine("error: '$version' is not a three part X.Y.Z version")
    exit 1
}
$major = [int]$Matches[1]
$minor = [int]$Matches[2]
$patch = [int]$Matches[3]

"version from $Pkg/package.json: $version"
''

Test-Version 'StandaloneMetadata pkg' $version `
    (Get-FirstMatch '.github/workflows/StandaloneMetadata/package.json' $JsonVersion)

Test-Version 'VERSION.txt' $version `
    ((Get-Content -Raw "$Pkg/Runtime/VERSION.txt") -replace '\s', '')

Test-Version 'CHANGELOG.md heading' $version `
    (Get-FirstMatch 'CHANGELOG.md' '^## ([0-9][0-9.]*)')

Test-Version 'AudioLinkAssetManager.cs' $version `
    (Get-FirstMatch "$Pkg/Editor/Scripts/AudioLinkAssetManager.cs" 'baseAssetsPath = "Samples/AudioLink/([^"]*)"')

# X.Y.Z: Major is X.00f, Minor is Y.0Zf.
$alCs = "$Pkg/Runtime/Scripts/AudioLink.cs"

Test-Version 'AudioLinkVersionNumberMajor' ('{0}.{1:D2}' -f $major, 0) `
    (Get-FirstMatch $alCs 'AudioLinkVersionNumberMajor\s*=\s*([0-9.]*)f')

Test-Version 'AudioLinkVersionNumberMinor' ('{0}.{1:D2}' -f $minor, $patch) `
    (Get-FirstMatch $alCs 'AudioLinkVersionNumberMinor\s*=\s*([0-9.]*)f')

''
if ($script:Failed) {
    'Version numbers disagree. See the release checklist in CONTRIBUTING.MD.'
    exit 1
}

'All version numbers agree.'
