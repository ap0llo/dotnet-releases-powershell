Remove-Module "DotNetReleasesPowershell" -Force -ErrorAction SilentlyContinue
Import-Module (Join-Path $PSScriptRoot "../src/DotNetReleasesPowershell.psm1" | Resolve-Path).Path

# Define Mocks in the Scope of the DotNetReleasesPowershell module.
# This is necessary to make Mocks work when running Invoke-Pester from a script
# See https://github.com/pester/Pester/issues/1777
$PSDefaultParameterValues = @{
    "Mock:ModuleName"              = "DotNetReleasesPowershell"
    "Assert-MockCalled:ModuleName" = "DotNetReleasesPowershell"
}

<#
.SYNOPSIS
    Creates a entry in the "releases-index.json" file as PSCustomObject.
    Use in conjunction with Get-ReleasesIndexResponse for mocking Invoke-WebRequest calls to get "releases-index.json"
#>
function Get-ReleasesIndexEntry {
    param (
        [Parameter(Mandatory = $false)][string]$ChannelVersion = "1.0",
        [Parameter(Mandatory = $false)][string]$LatestRelease = "1.0.1",
        [Parameter(Mandatory = $false)][string]$LatestReleaseDate = "2000-01-01",
        [Parameter(Mandatory = $false)][string]$SupportPhase = "Maintenance",
        [Parameter(Mandatory = $false)][string]$EolDate = $null,
        [Parameter(Mandatory = $false)][string]$ReleasesJsonUrl = "https.//example.com/1.0/releases.json"
    )

    $releasesIndexEntry = [PSCustomObject]@{
        'channel-version'     = $ChannelVersion
        'latest-release'      = $LatestRelease
        'latest-release-date' = $LatestReleaseDate
        'support-phase'       = $SupportPhase
        'releases.json'       = $ReleasesJsonUrl
    }

    if ($EolDate) {
        $releasesIndexEntry | Add-Member -MemberType NoteProperty -Name 'eol-date' -Value $EolDate
    }

    return $releasesIndexEntry
}

<#
.SYNOPSIS
    Gets a response object for requests to the "releases-index.json" file for mocking Invoke-WebRequest
.PARAMETER Entries
    The release channels to return in the mock respone.
    Use Get-ReleasesIndexEntry to construct entries.
#>
function Get-ReleasesIndexResponse {

    param(
        [PSCustomObject[]]$Entries
    )

    $json = [PSCustomObject]@{ 'releases-index' = $Entries } | ConvertTo-Json

    return [PSCustomObject]@{
        Content = $json
    }
}

<#
.SYNOPSIS
    Tests if the specified uri is an uri to the .NET "releases-index.json"
#>
function Test-ReleasesIndexUri {

    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()][System.Uri]$Uri
    )

    return $Uri.ToString().EndsWith("releases-index.json", [System.StringComparison]::OrdinalIgnoreCase)
}



<#
.SYNOPSIS
    Tests if the specified uri is an uri to the "releases.json" for the specified version
#>
function Test-ReleasesJsonUri {

    param (
        [Parameter(Mandatory = $true)][ValidateNotNull()][System.Uri]$Uri,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$ChannelVersion
    )

    return $Uri.ToString().EndsWith("$ChannelVersion/releases.json", [System.StringComparison]::OrdinalIgnoreCase)
}


function Get-ReleasesJsonResponse {

    param(
        [Parameter(Mandatory = $false)][string]$ChannelVersion = "1.0",
        [Parameter(Mandatory = $false)][string]$EolDate = $null
    )

    $rootObject = [PSCustomObject]@{
        'channel-version' = $ChannelVersion
        'releases-index'  = $Entries
    }

    if ($EolDate) {
        $rootObject | Add-Member -MemberType NoteProperty -Name 'eol-date' -Value $EolDate
    }

    $json = ConvertTo-Json $rootObject
    return [PSCustomObject]@{
        Content = $json
    }
}