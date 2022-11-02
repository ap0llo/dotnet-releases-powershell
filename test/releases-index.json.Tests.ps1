<#
.SYNOPSIS
    Test cases that verify assumptions this module makes about the .NET Core releases-index.json file
    are still true for the current online versions of these files
#>

. (Join-Path $PSScriptRoot "../src/model.ps1")

BeforeAll {
    . (Join-Path $PSScriptRoot "../src/variables.ps1")

    $releasesIndexResponse = Invoke-WebRequest -Uri $ReleaseIndexUri -ErrorAction SilentlyContinue -UseBasicParsing
    [PSObject]$releasesIndex = $null
    try {
        $releasesIndex = $releasesIndexResponse | ConvertFrom-Json
    }
    catch {
    }


    <#
    .SYNOPSIS
        Performs the specified assertion for every 'entry' of 'releases-index' in the 'releases-index.json' file
    #>
    function Assert-DotnetReleaseChannel([ScriptBlock]$ChannelAssertion) {
        [int]$index = 0;

        foreach ($channel in $releasesIndex.'releases-index') {

            $path = "releases-index.json/releases-index/$index[channel-version=$($channel.'channel-version')]"
            try {
                Invoke-Command -ScriptBlock $ChannelAssertion -ArgumentList $channel
            }
            catch {
                throw ( New-Object System.Exception -ArgumentList "Assertion failed at '$path'", $_.Exception )
            }
        }
    }

    <#
    .SYNOPSIS
        Verifies the specified object has a member with the specified name
    #>
    function Assert-HasMember {
        param(
            [Parameter(Mandatory = $true)][ValidateNotNull()][object]$Object,
            [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$MemberName
        )

        if (-not ($Object | Get-Member -Name $MemberName)) {
            throw "Object does not contain member '$MemberName'"
        }
    }
}


Describe "releases-index.json" {

    It "File exists at the expected location" {
        $releasesIndexResponse | Should -Not -BeNull
        $releasesIndexResponse.StatusCode | Should -Be 200
    }

    It "File is valid JSON" {
        $releasesIndex | Should -Not -BeNull
    }

    It "Property 'releases-index' exists " {
        Assert-HasMember $releasesIndex "releases-index"
    }

    Context "'releases-index'" {

        It "Property '<PropertyName>' exists" -TestCases @(
            @{ PropertyName = 'channel-version' }
            @{ PropertyName = 'latest-release' }
            @{ PropertyName = 'latest-release-date' }
            @{ PropertyName = 'releases.json' }
            @{ PropertyName = 'support-phase' }
        ) {
            param($PropertyName)

            Assert-DotnetReleaseChannel {
                param($channel)
                Assert-HasMember $channel $PropertyName
            }
        }

        It "Property '<PropertyName>' is not null or empty" -TestCases @(
            @{ PropertyName = 'channel-version' }
            @{ PropertyName = 'latest-release' }
            @{ PropertyName = 'latest-release-date' }
            @{ PropertyName = 'releases.json' }
            @{ PropertyName = 'support-phase' }
        ) {
            param($PropertyName)

            Assert-DotnetReleaseChannel {
                param($channel)
                $channel.$PropertyName | Should -Not -BeNullOrEmpty
            }
        }

        It "Property 'eol-date' is in format YYYY-MM-DD" {
            Assert-DotnetReleaseChannel {
                param($channel)
                $eolDate = $channel.'eol-date'
                if ($eolDate) {
                    $eolDate | Should -MatchExactly "^\d\d\d\d-\d\d-\d\d$"
                }
            }
        }

        It "Property 'latest-release-date' is in format YYYY-MM-DD" {
            Assert-DotnetReleaseChannel {
                param($channel)
                $channel.'latest-release-date' | Should -MatchExactly "^\d\d\d\d-\d\d-\d\d$"
            }
        }

        It "Property 'support-phase' is in [<KnownSupportPhases>]" -TestCases @(
            @{ KnownSupportPhases = [DotNetSupportPhase].GetEnumValues() | ForEach-Object { $value = $PSItem.ToString().ToLower(); if ($value -eq "GoLive") { $value = "go-live" } ; $value } }
        ) {
            param($KnownSupportPhases)

            Assert-DotnetReleaseChannel {
                param($channel)
                $channel.'support-phase' | Should -BeIn $KnownSupportPhases
            }
        }

        It "Property 'releases.json' is a valid uri" {
            Assert-DotnetReleaseChannel {
                param($channel)

                $return = $null
                $url = $channel.'releases.json'
                $isUri = [System.Uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$return)
                $isUri | Should -BeTrue
            }
        }
    }
}