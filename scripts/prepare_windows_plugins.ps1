param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath($ProjectRoot)
$taskManifestPath = Join-Path $taskProjectRoot '.flutter-plugins-dependencies'
if (-not (Test-Path -LiteralPath $taskManifestPath)) {
    throw 'Run flutter pub get before preparing the Windows plugin folders.'
}
$taskManifest = Get-Content -LiteralPath $taskManifestPath -Raw | ConvertFrom-Json
$taskLinkRoot = Join-Path $taskProjectRoot 'windows\flutter\ephemeral\.plugin_symlinks'
New-Item -ItemType Directory -Force -Path $taskLinkRoot | Out-Null
foreach ($taskPlugin in $taskManifest.plugins.windows) {
    if ($taskPlugin.name -notmatch '^[a-z][a-z0-9_]*$') { throw 'Invalid plugin name.' }
    $taskLinkPath = [IO.Path]::GetFullPath((Join-Path $taskLinkRoot $taskPlugin.name))
    $taskTargetPath = [IO.Path]::GetFullPath($taskPlugin.path).TrimEnd('\')
    if (-not $taskLinkPath.StartsWith($taskProjectRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'The generated plugin connection must stay inside this project.'
    }
    if (-not (Test-Path -LiteralPath $taskTargetPath -PathType Container)) {
        throw "Plugin dependency not installed: $($taskPlugin.name)"
    }
    if (Test-Path -LiteralPath $taskLinkPath) {
        $taskExisting = Get-Item -LiteralPath $taskLinkPath -Force
        $taskExistingTarget = @($taskExisting.Target)[0]
        if ($taskExistingTarget -and
            [IO.Path]::GetFullPath($taskExistingTarget).TrimEnd('\') -eq $taskTargetPath) {
            continue
        }
        throw "Stale generated plugin connection: $taskLinkPath. Extract the source into a fresh folder and retry."
    }
    # A directory junction is a normal Windows folder alias. It does not need
    # Developer Mode, change security settings, or copy downloaded dependencies.
    New-Item -ItemType Junction -Path $taskLinkPath -Target $taskTargetPath | Out-Null
}
Write-Output 'Windows plugin folder connections are ready.'
