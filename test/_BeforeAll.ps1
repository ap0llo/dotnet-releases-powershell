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
        [Parameter(Mandatory = $false)][string]$SupportPhase = "active",
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

    $json = [PSCustomObject]@{ 'releases-index' = $Entries } | ConvertTo-Json -Depth 10

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


function Get-ReleasesJsonEntry {
    param (
        [Parameter(Mandatory = $false)][string]$ReleaseDate = "2000-01-01",
        [Parameter(Mandatory = $false)][string]$ReleaseVersion = "1.0.1",
        [Parameter(Mandatory = $false)][PSCustomObject]$Sdk = $null,
        [Parameter(Mandatory = $false)][PSCustomObject]$Runtime = $null
    )

    $releasesJsonEntry = [PSCustomObject]@{
        'release-date'    = $ReleaseDate
        'release-version' = $ReleaseVersion
    }

    if ($Sdk) {
        $releasesJsonEntry | Add-Member -MemberType NoteProperty -Name 'sdk' -Value $Sdk
    }

    if ($Runtime) {
        $releasesJsonEntry | Add-Member -MemberType NoteProperty -Name 'Runtime' -Value $Runtime
    }

    return $releasesJsonEntry
}

function Get-ReleasesJsonSdkEntry {
    param (
        [Parameter(Mandatory = $false)][string]$Version = "1.0.0",
        [Parameter(Mandatory = $false)][PSCustomObject[]]$Files = @()
    )

    $sdk = [PSCustomObject]@{
        'version' = $Version
        'files'   = $Files
    }

    return $sdk
}


function Get-ReleasesJsonRuntimeEntry {
    param (
        [Parameter(Mandatory = $false)][string]$Version = "1.0.0",
        [Parameter(Mandatory = $false)][PSCustomObject[]]$Files = @()
    )

    $sdk = [PSCustomObject]@{
        'version' = $Version
        'files'   = $Files
    }

    return $sdk
}

function Get-ReleasesJsonFileEntry {
    param (
        [Parameter(Mandatory = $false)][string]$Name = "file1.zip",
        [Parameter(Mandatory = $false)][string]$RId = "win-x64",
        [Parameter(Mandatory = $false)][string]$Url = "https://example.com",
        [Parameter(Mandatory = $false)][string]$Hash = "abc123"
    )

    $file = [PSCustomObject]@{ }

    if ($null -ne $Name) {
        $file | Add-Member -MemberType NoteProperty -Name 'name' -Value $Name
    }

    if ($null -ne $RId) {
        $file | Add-Member -MemberType NoteProperty -Name 'rid' -Value $RId
    }

    if ($null -ne $Url) {
        $file | Add-Member -MemberType NoteProperty -Name 'url' -Value $Url
    }

    if ($null -ne $Hash) {
        $file | Add-Member -MemberType NoteProperty -Name 'hash' -Value $Hash
    }

    return $file
}

function Get-ReleasesJsonResponse {

    param(
        [Parameter(Mandatory = $false)][string]$ChannelVersion = "1.0",
        [Parameter(Mandatory = $false)][string]$SupportPhase = "active",
        [Parameter(Mandatory = $false)][string]$EolDate = $null,
        [Parameter(Mandatory = $false)][PSCustomObject[]]$Entries = $null
    )

    $rootObject = [PSCustomObject]@{
        'channel-version' = $ChannelVersion
        'releases'        = $Entries
        'support-phase'   = $SupportPhase
    }

    if ($EolDate) {
        $rootObject | Add-Member -MemberType NoteProperty -Name 'eol-date' -Value $EolDate
    }

    $json = ConvertTo-Json $rootObject -Depth 10
    return [PSCustomObject]@{
        Content = $json
    }
}