<#
.SYNOPSIS
    Gets the installed versions of .NET Core
.DESCRIPTION
    Gets the installed versions of the .NET Core runtime and/or SDK.
.PARAMETER PackageType
    Specifies which types of .NET Core installation to return.
    Valid values are "Runtime", "Sdk" and "All" (default)
.EXAMPLE
    Get-DotNetInstallation -PackageType "Runtime"

    Get all installed .NET Core runtimes
#>
function Get-DotNetInstallation {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)][ValidateSet("Runtime", "Sdk", "All")][string]$PackageType
    )

    # If no PackageType was specified, default to "All"
    if (-not $PackageType) {
        $PackageType = "All"
    }


    $dotNetCommand = Get-Command -Name "dotnet" -CommandType Application
    if (-not $dotNetCommand) {
        return
    }

    # Get SDK installations
    if (($PackageType -eq "Sdk") -or ($PackageType -eq "All")) {

        $command = "dotnet --list-sdks"
        $output = Invoke-Expression $command
        if ($LASTEXITCODE -ne 0) {
            throw "Command '$command' completed with exit code $LASTEXITCODE"
        }

        # dotnet --list-sdks returns runtimes in the Format
        # VERSION [LOCATION], e.g.
        # 3.1.101 [C:\Program Files\dotnet\sdk]
        foreach ($outputLine in $output) {
            if (-not $outputLine.Contains("[")) {
                continue
            }

            $_index = $outputLine.IndexOf("[")
            $_version = $outputLine.Substring(0, $_index).Trim()
            $_location = $outputLine.Substring($_index).Trim().Trim('[', ']')

            $installation = [DotNetInstallation]::new(
                "Sdk",
                "",
                $_version,
                $_location
            )

            # output value to pipeline
            $installation
        }
    }


    # Get Runtime installations
    if (($PackageType -eq "Runtime") -or ($PackageType -eq "All")) {

        $command = "dotnet --list-runtimes"
        $output = Invoke-Expression $command
        if ($LASTEXITCODE -ne 0) {
            throw "Command '$command' completed with exit code $LASTEXITCODE"
        }

        # dotnet --list-runtimes returns runtimes in the Format
        # NAME VERSION [LOCATION], e.g.
        # Microsoft.AspNetCore.All 2.1.11 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All]

        foreach ($outputLine in $output) {
            if (-not $outputLine.Contains("[")) {
                continue
            }

            $_bracketIndex = $outputLine.IndexOf("[")
            $_nameAndVersion = $outputLine.Substring(0, $_bracketIndex).Trim()
            $_location = $outputLine.Substring($_bracketIndex).Trim().Trim('[', ']')

            if (-not $_nameAndVersion.Contains(" ")) {
                continue
            }

            $_spaceIndex = $_nameAndVersion.IndexOf(" ")
            $_name = $_nameAndVersion.Substring(0, $_spaceIndex).Trim()
            $_version = $_nameAndVersion.Substring($_spaceIndex).Trim()

            $installation = [DotNetInstallation]::new(
                "Runtime",
                $_name,
                $_version,
                $_location
            )

            # output value to pipeline
            $installation
        }
    }
}
