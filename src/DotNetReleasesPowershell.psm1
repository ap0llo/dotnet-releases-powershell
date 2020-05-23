# See https://github.com/dotnet/core/tree/master/release-notes
$ReleaseIndexUri = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"

. (Join-Path $PSScriptRoot "model.ps1")

$commandFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot "commands") -Filter "*.ps1"

foreach($file in $commandFiles) {
    . $file.FullName
}