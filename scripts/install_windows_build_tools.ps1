# Run this script yourself and approve the Windows administrator prompt.
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$toolingRoot = Join-Path $projectRoot '.tooling'
New-Item -ItemType Directory -Force -Path $toolingRoot | Out-Null
$installerPath = Join-Path $toolingRoot 'vs_BuildTools.exe'
if (-not (Test-Path -LiteralPath $installerPath)) {
    Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vs_BuildTools.exe' -OutFile $installerPath
}
$signature = Get-AuthenticodeSignature -LiteralPath $installerPath
if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
    throw 'The installer must have a valid Microsoft signature. Installation stopped.'
}
Write-Host 'Approve the Windows administrator prompt to install the native C++ toolchain.'
$installerArguments = @('--passive', '--wait', '--norestart', '--nocache',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools', '--includeRecommended')
$installerProcess = Start-Process -FilePath $installerPath -ArgumentList $installerArguments -Verb RunAs -PassThru -Wait
if ($installerProcess.ExitCode -notin @(0, 3010)) {
    throw ('Build Tools installation failed with exit code ' + $installerProcess.ExitCode)
}
if ($installerProcess.ExitCode -eq 3010) {
    Write-Host 'Installation finished. Windows reports that a restart is required.'
} else {
    Write-Host 'Installation finished. Run flutter doctor -v to verify the toolchain.'
}

