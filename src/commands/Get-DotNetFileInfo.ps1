<#
.SYNOPSIS
    Get information about files that are part of a .NET Core release
.DESCRIPTION
    Each .NET Core release includes one or more files (e.g. installers for the runtime or the SDK).
    The Get-DotNetFileInfo retrieves information about one or more files based on the specified criteria.
    When no critieria are specified, all files from all .NET Core releases are returned.
.PARAMETER Channel
    Limit releases to a release channel (Use Get-DotNetReleaseChannel command to get a release channel).
    Channel parameter can be taken from the pipeline.
.PARAMETER ChannelVersion
    Limit files to a .NET Core release channel
.PARAMETER ReleaseInfo
    Specifies the files to get information on as release info object (as returned by Get-DotNetFileReleaseInfo).
    Accepts value from pipeline.
.PARAMETER ReleaseVersion
    Limit results to a specific .NET Core relrease
.PARAMETER SdkVersion
    Limit results to the .NET Core release the specified version of the SDK belongs to.
.PARAMETER PackageType
    Limit files to either .NET Core Runtime or .NET Core SDK releases.
    Valid values are 'Runtime', 'Sdk' or 'All' (default)
.PARAMETER RuntimeIdentifier
    Limit results to files for a specific operating system.
.PARAMETER Extension
    Limit results to files with a specific file extension.
    E.g. Get the Windows installer files by limiting to 'exe'.
.EXAMPLE
    Get-DotNetFileInfo -ChannelVersion "3.1"

    Get all files that belong to any .NET Core 3.1 release
.EXAMPLE
    Get-DotnetFileInfo -SdkVersion "3.1.201" -PackageType "Sdk" -RuntimeIdentifier "win-x64"

    Get all .NET Core SDK files of SDK version 3.1.201 for 64bit Windows
.EXAMPLE
    Get-DotNetReleaseChannel -Channel 2.1 | Get-DotNetFileInfo

    Get all files for all releases in a  channel using the pipeline
.EXAMPLE
    Get-DotNetFileInfo

    Get information about all files for all releases
#>
function Get-DotNetFileInfo {

    [CmdletBinding(DefaultParameterSetName = "FromChannelInfo")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromChannelInfo")]
        [DotNetChannelInfo[]] $Channel,

        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [string]$ChannelVersion,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromReleaseInfo")]
        [DotNetReleaseInfo[]]$ReleaseInfo,

        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromReleaseInfo")]
        [string]$ReleaseVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromReleaseInfo")]
        [string]$SdkVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromReleaseInfo")]
        [ValidateSet("Runtime", "Sdk", "All")]
        [string]$PackageType,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromReleaseInfo")]
        [string]$RuntimeIdentifier,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromReleaseInfo")]
        [string]$Extension
    )

    BEGIN { }
    PROCESS {

        # When no PackageType is set, default to "All"
        if (-not $PackageType) {
            $PackageType = "All"
        }

        switch ($PsCmdlet.ParameterSetName) {
            "FromChannelInfo" {
                if (-not $Channel) {
                    $Channel = Get-DotNetReleaseChannel
                }
                $ReleaseInfo = @()
                foreach ($channelInfo in $Channel) {
                    $ReleaseInfo += ($channelInfo | Get-DotNetReleaseInfo -ReleaseVersion $ReleaseVersion -SdkVersion $SdkVersion)
                }
            }
            "FromChannelVersion" {
                $Channel = Get-DotNetReleaseChannel -ChannelVersion $ChannelVersion
                $ReleaseInfo = @()
                foreach ($channelInfo in $Channel) {
                    $ReleaseInfo += ($channelInfo | Get-DotNetReleaseInfo -ReleaseVersion $ReleaseVersion -SdkVersion $SdkVersion)
                }
            }
            "FromReleaseInfo" {
                if (-not $ReleaseInfo) {
                    $ReleaseInfo = Get-DotNetReleaseInfo `
                        -ReleaseVersion $ReleaseVersion `
                        -SdkVersion $SdkVersion
                }
            }
            default {
                throw "Unexpected ParameterSetName '$($PsCmdlet.ParameterSetName)'"
            }
        }


        # Get files from release infos
        $files = @()
        # Include Runtime files
        $files += @($ReleaseInfo | Select-Object -ExpandProperty Runtime | Select-Object -ExpandProperty Files)
        # Include SDK files
        $files += @($ReleaseInfo | Select-Object -ExpandProperty Sdk | Select-Object -ExpandProperty Files)

        # When set, filter files based on package type
        if ($PackageType -ne "All") {
            $files = $files | Where-Object -FilterScript { $PSItem.PackageType -eq $PackageType }
        }

        # when specified, filter files by runtime identifier
        if ($RuntimeIdentifier) {
            $files = $files | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $RuntimeIdentifier }
        }

        # when specified, filter files by file extension
        if ($Extension) {
            $files = $files | Where-Object -FilterScript { $PSItem.Extension -eq $Extension }
        }

        # Return value to pipeline
        $files
    }
    END { }
}
