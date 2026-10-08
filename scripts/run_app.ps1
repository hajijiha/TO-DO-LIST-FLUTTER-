param([switch]$Profile, [switch]$Build)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$localFlutter = Join-Path $projectRoot '.tooling\flutter\bin\flutter.bat'
if (Test-Path -LiteralPath $localFlutter) {
    $flutterCommand = $localFlutter
    $env:PUB_CACHE = Join-Path $projectRoot '.tooling\pub-cache'
} else {
    $resolvedFlutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $resolvedFlutter) {
        throw 'Flutter SDK is required. See README section 1 for installation and PATH setup.'
    }
    $flutterCommand = $resolvedFlutter.Source
}
$taskPreviousPreference = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    $taskPubOutput = @(& $flutterCommand pub get 2>&1)
    $taskPubExit = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $taskPreviousPreference
}
$taskPubOutput | ForEach-Object { Write-Output $_ }
if ($taskPubExit -ne 0) {
    $taskManifestExists = Test-Path -LiteralPath (Join-Path $projectRoot '.flutter-plugins-dependencies')
    $taskSymlinkFailure = ($taskPubOutput | Out-String) -match 'symlink support|symlink.*privilege|Developer Mode'
    if (-not ($taskManifestExists -and $taskSymlinkFailure)) { exit $taskPubExit }
    & (Join-Path $PSScriptRoot 'prepare_windows_plugins.ps1') -ProjectRoot $projectRoot
    & $flutterCommand pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
& (Join-Path $PSScriptRoot 'prepare_windows_plugins.ps1') -ProjectRoot $projectRoot
if ($Build) {
    & $flutterCommand build windows --no-pub
} elseif ($Profile) {
    & $flutterCommand run -d windows --profile --no-pub
} else {
    & $flutterCommand run -d windows --no-pub
}
exit $LASTEXITCODE

