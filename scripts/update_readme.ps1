param([string]$PythonPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
if ($PythonPath) {
    if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) { throw 'Python executable not found.' }
    $pythonCommand = $PythonPath
} else {
    $resolvedPython = Get-Command python -ErrorAction SilentlyContinue
    if (-not $resolvedPython) { throw 'Install Python with reportlab and Pillow first. See README section 8.' }
    $pythonCommand = $resolvedPython.Source
}
& $pythonCommand -c 'import reportlab, PIL'
if ($LASTEXITCODE -ne 0) {
    throw 'The selected Python needs reportlab and Pillow. Run python -m pip install reportlab Pillow.'
}
& $pythonCommand (Join-Path $PSScriptRoot 'build_readme_pdf.py')
exit $LASTEXITCODE
