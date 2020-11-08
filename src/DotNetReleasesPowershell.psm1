. (Join-Path $PSScriptRoot "variables.ps1")
. (Join-Path $PSScriptRoot "model.ps1")

$commandFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "commands") -Filter "*.ps1"

foreach ($file in $commandFiles) {
    . $file.FullName
}