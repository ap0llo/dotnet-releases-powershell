<#
.SYNOPSIS
    Installs a .NET Core package
.DESCRIPTION
    Downloads and installs a .NET Core package.
    When run without admin privileges, a UAC prompt will appear during installation.
    Currently only supports running the machine-wide installer for Windows.
    The command expects to find only a single installer using the specified criteria and will throw an error if multiple files are found.
.PARAMETER PackageType
    Specifies the type of package to install. Value must be either "Runtime" or "SDK"
.PARAMETER ReleaseVersion
    Specifies the version of .NET Core to install
.PARAMETER SdkVersion
    Specifies the version of the .NET Core runtime to install.
    Using the 'SdkVersion' parameter always installs the .NET Core SDK.
    The parameter cannot be used in conjunction with 'PackageType'
.PARAMETER ReleaseInfo
    Specifies the .NET Core version to install using a release info object (as returned by 'Get-DotNetReleaseInfo')
.EXAMPLE
    Install-Dotnet -SdkVersion 3.1.300

    Install the .NET SDK 3.1.300
.EXAMPLE
    Install-DotNet -RelaseVersion "3.1.2" -PackageType "Runtime"

    Install the .NET Core runtime 3.1.2
#>
function Install-DotNet {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromReleaseVersion")]
        [Parameter(Mandatory = $true, ParameterSetName = "FromDotNetReleaseInfo")]
        [ValidateSet("Runtime", "Sdk")]
        [string]$PackageType,

        [Parameter(Mandatory = $true, ParameterSetName = "FromReleaseVersion")][string]$ReleaseVersion,

        [Parameter(Mandatory = $true, ParameterSetName = "FromSdkVersion")][string]$SdkVersion,

        [Parameter(Mandatory = $true, ParameterSetName = "FromDotNetReleaseInfo", ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [DotNetReleaseInfo]$ReleaseInfo
    )


    function GetRid {
        # Determine runtime identifier for current OS
        $platform = [System.Environment]::OSVersion.Platform
        switch ($platform) {
            "Win32NT" {
                if ([System.Environment]::Is64BitOperatingSystem) {
                    return "win-x64"
                }
                else {
                    return "win-x86"
                }
            }
            default {
                throw "Unimplemented platform '$platform'"
            }
        }
    }

    $_runtimeIdentifier = GetRid

    Write-Verbose "Determined current Runtime Identifier to be '$_runtimeIdentifier'"

    $_files = @()

    Write-Verbose "ParameterSetName is '$($PsCmdlet.ParameterSetName)', PackageType is '$PackageType' "
    switch ($PsCmdlet.ParameterSetName) {
        "FromReleaseVersion" {
            $_files = Get-DotNetFileInfo -RuntimeIdentifier $_runtimeIdentifier `
                -ReleaseVersion $ReleaseVersion `
                -PackageType $PackageType `
                -Extension "exe"
        }
        "FromSdkVersion" {
            $PackageType = "Sdk"
            $_files = Get-DotNetFileInfo -RuntimeIdentifier $_runtimeIdentifier `
                -SdkVersion $SdkVersion `
                -PackageType $PackageType `
                -Extension "exe"

        }
        "FromDotNetReleaseInfo" {

            switch ($PackageType) {
                "Sdk" {
                    $_files = $ReleaseInfo.Sdk.Files `
                    | Where-Object -FilterScript { $PSItem.Extension -eq "exe" } `
                    | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $_runtimeIdentifier }
                }
                "Runtime" {
                    $_files = $ReleaseInfo.Runtime.Files `
                    | Where-Object -FilterScript { $PSItem.Extension -eq "exe" } `
                    | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $_runtimeIdentifier }
                }
                default {
                    throw "Unexpected package type '$PackageType'"
                }
            }
        }
        default {
            throw "Unexpected ParameterSetName '$($PsCmdlet.ParameterSetName)'"
        }
    }

    $_count = ($_files | Measure-Object).Count

    if ($_count -eq 0) {
        throw "Failed to find a matching installer"
    }
    if ($_count -gt 1) {
        throw "Found multiple installers matching the specified criteria"
    }

    if (Test-DotNetInstallation -PackageType $PackageType -Version $_files.Version) {
        throw ".NET $PackageType, version $($_files.Version) is already installed"
    }
    else {

        Write-Verbose "Installing .NET $($_files.PackageType), version $($_files.Version)"
        $_installerFile = Get-DotNetFile -FileInfo $_files
        Start-DotNetInstaller -InstallerPath $_installerFile.FullName

        Write-Verbose "Deleting temporary installer file '$($_installerFile.FullName)'"
        try {
            Remove-Item -Path $_installerFile.FullName
        }
        catch {
            # Ignore errors
        }
    }
}
