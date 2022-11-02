<#
.SYNOPSIS
    Get information about .NET Core Release channels.
.DESCRIPTION
    Gets information about a .NET Core release channel.
    Information includes the name/version of the channel, the latest release and the uri to get the releases for this channel from.

    To get a channel's releases, use the Get-DotnetReleaseInfo command.
.PARAMETER ChannelVersion
    Limits the result to channels of the specified version.
    .PARAMETER SupportPhase
    Limits the result to channels in the specified support phase.
    Valid values are 'Preview', 'LTS', 'EOL' and 'Maintenance'.
.EXAMPLE
    Get-DotNetReleaseChannel

    Get all .NET Core release channels
.EXAMPLE
    Get-DotNetReleaseChannel -ChannelVersion "3.1"

    Get information for the .NET Core 3.1 release channel.
.EXAMPLE
    Get-DotNetReleaseChannel -SupportPhase LTS

    Get all "long-term support" release channels
#>
function Get-DotNetReleaseChannel {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$ChannelVersion,
        [Parameter(Mandatory = $false)][DotNetSupportPhase]$SupportPhase
    )

    $response = Invoke-WebRequest -Uri $ReleaseIndexUri -UseBasicParsing
    $releaseIndex = $response.Content | ConvertFrom-Json

    foreach ($obj in $releaseIndex.'releases-index') {

        [Nullable[DateTime]]$eolDate = $null
        if ($obj.'eol-date') {
            $eolDate = [DateTime]::Parse($obj.'eol-date')
        }

        [DotNetChannelInfo]$channelInfo = [DotNetChannelInfo]::new(
            $obj.'channel-version',
            $obj.'latest-release',
            [DateTime]::Parse($obj.'latest-release-date'),
            $obj.'releases.json',
            $eolDate,
            (Get-DotNetSupportPhase $obj.'support-phase')
        )

        # Skip non-matching results when ChannelVersion version was set
        if ($ChannelVersion -and ($channelInfo.ChannelVersion -ne $ChannelVersion)) {
            continue
        }

        # Skip non-matching results when SupportPhase version was set
        if ($SupportPhase -and ($channelInfo.SupportPhase -ne $SupportPhase)) {
            continue
        }

        # Return channel info to pipeline
        $channelInfo
    }
}