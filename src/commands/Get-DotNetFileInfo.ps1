<#
.SYNOPSIS
    Get information about files that are part of a .NET Core release
.DESCRIPTION
    Each .NET Core release includes one or more files (e.g. installers for the runtime or the SDK).
    The Get-DotNetFileInfo retrieves information about one or more files based on the specified criteria.
    When no critieria are specified, all files from all .NET Core releases are returned.
.PARAMETER ChannelVersion
    Limit files to a .NET Core release channel
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
#>
function Get-DotNetFileInfo {

    # TODO: Add 'Channel' Parameter

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$ChannelVersion,
        [Parameter(Mandatory = $false)][string]$ReleaseVersion,
        [Parameter(Mandatory = $false)][string]$SdkVersion,
        [Parameter(Mandatory = $false)][ValidateSet("Runtime", "Sdk", "All")] [string]$PackageType,
        [Parameter(Mandatory = $false)] [string]$RuntimeIdentifier,
        [Parameter(Mandatory = $false)] [string]$Extension
    )

    # When no PackageType is set, default to "All"
    if (-not $PackageType) {
        $PackageType = "All"
    }

    # Get channel (pass in ChannelVersion to limit result)
    $channelInfo = Get-DotNetReleaseChannel -ChannelVersion $ChannelVersion

    # Get all release infos for all channels
    $releaseInfos = $channelInfo | Get-DotNetReleaseInfo -ReleaseVersion $ReleaseVersion -SdkVersion $SdkVersion

    # Get files from release infos
    $files = @()
    # Include Runtime files
    $files += @($releaseInfos | Select-Object -ExpandProperty Runtime | Select-Object -ExpandProperty Files)
    # Include SDK files
    $files += @($releaseInfos | Select-Object -ExpandProperty Sdk | Select-Object -ExpandProperty Files)

    # When set, filter files based on package type
    if ($PackageType -ne "all") {
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

    return $files
}
