<#
.SYNOPSIS
    Checks if a .NET Core installation exists
.DESCRIPTION
    Tests whether a .NET Core runtime or SDK is installed.
.PARAMETER PackageType
    Specifies the type of installation to check for.
    Valid values are "Runtime", "Sdk" and "All" (default)
.PARAMETER Version
    Specifies the version of the installation to check for.
.EXAMPLE
    Test-DotNetInstallation -PackageType "Runtime"

    Check if any .NET Core runtime is installed
.EXAMPLE
    Test-DotNetInstallation -PackageType "Sdk" -Version "3.1.200"

    Check if the .NET Core SDK 3.1.201 is installed
#>
function Test-DotNetInstallation {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][ValidateSet("Runtime", "Sdk", "All")][string]$PackageType,
        [Parameter(Mandatory = $false)][string]$Version
    )

    # If no PackageType was specified, default to "All"
    if (-not $PackageType) {
        $PackageType = "All"
    }

    $installations = Get-DotNetInstallation -PackageType $PackageType

    if ($Version) {
        $installations = $installations | Where-Object -FilterScript { $PSItem.Version -eq $Version }
    }

    $count = ($installations | Measure-Object).Count
    return ($count -gt 0)
}