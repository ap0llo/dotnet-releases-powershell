<#
.SYNOPSIS
    Get information about a .NET Core release.
.DESCRIPTION
    Gets detailed information about a .NET Core releases.
    Information includes the version, the release channel, the release date and a list of files for both runtime and SDK.
    By default, all releases from all channels are returned.
.PARAMETER Channel
    Limit releases to a release channel (Use Get-DotNetReleaseChannel command to get a release channel).
    Channel parameter can be taken from the pipeline.
.PARAMETER ChannelVersion
    Limit results to a specific release channel.
.PARAMETER ReleaseVersion
    Limit results to only include the specified release.
.PARAMETER SdkVersion
    Limit results to the release the specified version of the .NET Core SDK belongs to.
.PARAMETER Latest
    Only returns the latest release of a release channel.
.EXAMPLE
    Get-DotNetReleaseChannel -ChannelVersion 3.1 | Get-DotnetReleaseInfo

    Get all releases for a channel from a release channel object.
.EXAMPLE
    Get-DotnetReleaseInfo -ChannelVersion 2.1

    Get all releases of .NET Core 2.1.
.EXAMPLE
    Get-DotnetReleaseInfo -ChannelVersion 3.1 -Latest

    Get the latest release of .NET Core 3.1.
#>
function Get-DotNetReleaseInfo {

    [CmdletBinding(DefaultParameterSetName = "FromChannelInfo")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromChannelInfo")]
        [ValidateNotNull()]
        [DotNetChannelInfo[]] $Channel,

        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [string]$ChannelVersion,

        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [string]$ReleaseVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [string]$SdkVersion,
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory = $false, ParameterSetName = "FromChannelInfo")]
        [switch]$Latest
    )

    BEGIN { }
    PROCESS {

        function GetFileInfos($packageType, $version, $thisReleaseVersion, $jsonFilesArray) {
            foreach ($jsonObject in $jsonFilesArray) {
                $name = $jsonObject.'name'
                $fileInfo = [DotNetFileInfo]::new(
                    $packageType,
                    $version,
                    $thisReleaseVersion,
                    $name,
                    [System.IO.Path]::GetExtension($name).Trim("."),
                    $jsonObject.'rid',
                    [Uri]$jsonObject.'url',
                    $jsonObject.'hash'
                )

                #return to pipeline
                $fileInfo
            }
        }

        function GetRuntimeReleaseInfo($thisReleaseVersion, $runtimeJsonObject) {
            Write-Verbose "Reading runtime info for version '$thisReleaseVersion'"
            $version = $runtimeJsonObject.'version'
            $runtimeFiles = GetFileInfos -packageType "Runtime" `
                -version $version `
                -thisReleaseVersion $thisReleaseVersion `
                -jsonFilesArray $runtimeJsonObject.'files'
            return [DotNetRuntimeReleaseInfo]::new(
                $thisReleaseVersion,
                $version,
                $runtimeFiles
            )
        }

        function GetSdkReleaseInfo($thisReleaseVersion, $sdkJsonObject) {
            Write-Verbose "Reading SDK info for version '$thisReleaseVersion'"
            $version = $sdkJsonObject.'version'
            $sdkFiles = GetFileInfos -packageType "Sdk" `
                -version $version `
                -thisReleaseVersion $thisReleaseVersion `
                -jsonFilesArray $sdkJsonObject.'files'
            return [DotNetSdkReleaseInfo]::new(
                $thisReleaseVersion,
                $version,
                $sdkFiles
            )
        }

        switch ($PsCmdlet.ParameterSetName) {
            "FromChannelInfo" {
                if (-not $Channel) {
                    $Channel = Get-DotNetReleaseChannel
                }
            }
            "FromChannelVersion" {
                $Channel = Get-DotNetReleaseChannel -ChannelVersion $ChannelVersion
            }
            default {
                throw "Unexpected ParameterSetName '$($PsCmdlet.ParameterSetName)'"
            }
        }

        foreach ($channelInfo in $Channel) {

            Write-Verbose "Getting release infos for channel '$($channelInfo.ChannelVersion)'"

            $response = Invoke-WebRequest -Uri $channelInfo.ReleasesJsonUri
            $releaseInfoJson = $response.Content | ConvertFrom-Json

            $latestRelease = $releaseInfoJson.'latest-release'

            foreach ($releaseJson in $releaseInfoJson.'releases') {

                $thisReleaseVersion = $releaseJson.'release-version'

                Write-Verbose "Reading release info for version '$thisReleaseVersion' "

                $runtimeInfo = GetRuntimeReleaseInfo $thisReleaseVersion $releaseJson.'runtime'
                $sdkInfo = GetSdkReleaseInfo $thisReleaseVersion $releaseJson.'sdk'

                $releaseInfo = [DotNetReleaseInfo]::new(
                    $channelInfo.ChannelVersion,
                    $thisReleaseVersion,
                    [DateTime]::Parse($releaseJson.'release-date'),
                    $runtimeInfo,
                    $sdkInfo
                )

                if ($ReleaseVersion -and ($releaseInfo.Version -ne $ReleaseVersion)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because it does not match the value of the '-ReleaseVersion' parameter"
                    continue
                }

                if ($Latest -and ($releaseInfo.Version -ne $latestRelease)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because it is not the latest release and the  '-Latest' switch was set"
                    continue
                }

                if ($SdkVersion -and ($releaseInfo.Sdk.Version -ne $SdkVersion)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because the SDK version '$($releaseInfo.Sdk.Version)' does not match the value of the '-SdkVersion' parameter"
                    continue
                }

                # Return release info to pipeline
                $releaseInfo
            }
        }
    }
    END { }
}
