param([string]$Destination = 'submission')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$destinationRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot $Destination))
if (-not $destinationRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'The submission folder must be inside this project.'
}
$stageRoot = Join-Path $destinationRoot ('today_todo_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
$fileNames = @('pubspec.yaml','pubspec.lock','analysis_options.yaml','.metadata','.gitignore','.gitattributes','README.md','앱 실행.cmd')
foreach ($fileName in $fileNames) {
    $sourcePath = Join-Path $projectRoot $fileName
    if (Test-Path -LiteralPath $sourcePath) {
        Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $stageRoot $fileName)
    }
}
$sourceFolders = @('lib','test','test_driver','windows','android','scripts','docs')
foreach ($sourceFolder in $sourceFolders) {
    $folderPath = Join-Path $projectRoot $sourceFolder
    if (-not (Test-Path -LiteralPath $folderPath)) { continue }
    Get-ChildItem -LiteralPath $folderPath -File -Recurse -Force | ForEach-Object {
        $relativePath = $_.FullName.Substring($projectRoot.Length + 1)
        if ($relativePath -match '^docs\\results\\') { return }
        if ($relativePath -match '^docs\\evidence\\' -and
            $_.Name -notmatch '^(simple_|profile_workload|timeline_check|devtools_observations)') { return }
        if ($relativePath -match '(^|\\)(ephemeral|\.gradle|\.kotlin|\.dart_tool|build|__pycache__)(\\|$)' -or
            $relativePath -match '(^|\\)(local\.properties|gradle-wrapper\.jar|gradlew|gradlew\.bat|GeneratedPluginRegistrant\.java)$' -or
            $relativePath -match '\.(iml|pyc)$') { return }
        $targetPath = Join-Path $stageRoot $relativePath
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $targetPath) | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $targetPath
    }
}
$readmePDF = Join-Path $projectRoot 'output\pdf\Readme.pdf'
if (-not (Test-Path -LiteralPath $readmePDF)) { throw 'Create output/pdf/Readme.pdf first.' }
Copy-Item -LiteralPath $readmePDF -Destination (Join-Path $stageRoot 'Readme.pdf')
$archivePath = $stageRoot + '.zip'
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory(
    $stageRoot,
    $archivePath,
    [IO.Compression.CompressionLevel]::Optimal,
    $false
)
Write-Output $archivePath
