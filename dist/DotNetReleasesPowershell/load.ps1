<#
.SYNOPSIS
    This script downloads the latest version of the DotNetReleasesPowershell from GitHub and loads it into the current Powershell process
#>

$moduleName = "DotNetReleasesPowershell"
$downloadUrl = "https://raw.githubusercontent.com/ap0llo/dotnet-releases-powershell/master/dist/DotNetReleasesPowershell/DotNetReleasesPowershell.psm1"

# Download module from GitHub
$tempDirectory = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), [System.IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $tempDirectory | Out-Null
$localModulePath = Join-Path $tempDirectory "$moduleName.psm1"
Invoke-WebRequest -Uri $downloadUrl -OutFile $localModulePath -UseBasicParsing

# Unload module if it is already loaded
Remove-Module -Name $moduleName -Force -ErrorAction SilentlyContinue

# Load downloaded module
Import-Module -FullyQualifiedName $localModulePath
