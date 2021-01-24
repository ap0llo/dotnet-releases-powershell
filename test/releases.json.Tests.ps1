<#
.SYNOPSIS
    Test cases that verify assumptions this module makes about the .NET Core releases.json files
    are still true for the current online versions of these files
#>

. (Join-Path $PSScriptRoot "../src/model.ps1")

BeforeAll {

    . (Join-Path $PSScriptRoot "../src/variables.ps1")

    # Load all releases.json files

    [PSObject]$releasesIndex = Invoke-WebRequest -Uri $ReleaseIndexUri -ErrorAction SilentlyContinue -UseBasicParsing | ConvertFrom-Json

    $releaseMetadatas = @()
    foreach ($releasesIndexEntry in $releasesIndex.'releases-index') {

        $releasesJsonUrl = $releasesIndexEntry.'releases.json'
        $releasesJson = Invoke-WebRequest -Uri $releasesJsonUrl | ConvertFrom-Json

        $releaseMetadatas += [PSCustomObject]@{
            ChannelVersion = $releasesIndexEntry.'channel-version'
            ReleasesJson   = $releasesJson
        }
    }

    <#
    .SYNOPSIS
        Performs the specified assertion for every 'releases.json' file
    #>
    function Assert-ReleasesJson([ScriptBlock]$Assertion) {
        foreach ($entry in $releaseMetadatas) {
            $path = "releases.json[channel-version=$($entry.ChannelVersion)]"
            try {
                Invoke-Command -ScriptBlock $Assertion -ArgumentList $entry.ReleasesJson
            }
            catch {
                throw ( New-Object System.Exception -ArgumentList "Assertion failed at '$path'", $_.Exception )
            }
        }
    }


    <#
    .SYNOPSIS
        Performs the specified assertion for every 'releases' entry in every 'releases.json' file
    #>
    function Assert-ReleasesJsonEntry([ScriptBlock]$Assertion) {

        foreach ($entry in $releaseMetadatas) {

            [int]$index = 0
            foreach ($release in $entry.ReleasesJson.'releases') {

                $path = "releases.json[channel-version=$($entry.ChannelVersion)]/releases/$index[release-version=$($release.'release-version')]"

                try {
                    Invoke-Command -ScriptBlock $Assertion -ArgumentList $release
                }
                catch {
                    throw ( New-Object System.Exception -ArgumentList "Assertion failed at '$path'", $_.Exception )
                }

                $index += 1
            }
        }
    }

    <#
    .SYNOPSIS
        Performs the specified assertion for every 'files' entry under 'sdk' for every 'releases' entry in every 'releases.json file'
    #>
    function Assert-ReleasesJsonEntryFile {

        param(
            [Parameter(Mandatory = $true)][ValidateSet("runtime", "sdk")][string]$PackageType,
            [Parameter(Mandatory = $true)][ValidateNotNull()][ScriptBlock]$Assertion
        )

        foreach ($entry in $releaseMetadatas) {

            [int]$releasesIndex = 0
            foreach ($release in $entry.ReleasesJson.'releases') {

                [int]$fileIndex = 0

                if (-not $release.$PackageType) {
                    continue
                }

                foreach ($file in $release.$PackageType.'files') {

                    $path = "releases.json[channel-version=$($entry.ChannelVersion)]/releases/$releasesIndex[release-version=$($release.'release-version')]/$PackageType/files/$fileIndex[name=$($file.'name')]"

                    try {
                        Invoke-Command -ScriptBlock $Assertion -ArgumentList $file
                    }
                    catch {
                        throw ( New-Object System.Exception -ArgumentList "Assertion failed at '$path'", $_.Exception )
                    }

                    $fileIndex += 1
                }

                $releasesIndex += 1
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


Describe "releases.json" {

    Context "Root object" {

        It "Property '<PropertyName>' exists" -TestCases @(
            @{ PropertyName = 'latest-release' }
            @{ PropertyName = 'support-phase' }
            @{ PropertyName = 'releases' }
        ) {
            param($PropertyName)

            Assert-ReleasesJson {
                param($releasesJson)
                Assert-HasMember $releasesJson $PropertyName
            }
        }

        It "Property '<PropertyName>' is not null or empty" -TestCases @(
            @{ PropertyName = 'latest-release' }
            @{ PropertyName = 'support-phase' }
            @{ PropertyName = 'releases' }
        ) {
            param($PropertyName)

            Assert-ReleasesJson {
                param($releasesJson)
                $releasesJson.$PropertyName | Should -Not -BeNullOrEmpty
            }
        }

        It "Property 'eol-date' is in format YYYY-MM-DD" {
            Assert-ReleasesJson {
                param($releasesJson)
                $eolDate = $releasesJson.'eol-date'
                if ($eolDate) {
                    $eolDate | Should -MatchExactly "^\d\d\d\d-\d\d-\d\d$"
                }
            }
        }

        It "Value of property 'support-phase' is in [<KnownSupportPhases>]" -TestCases @(
            @{ KnownSupportPhases = [DotNetSupportPhase].GetEnumValues() }
        ) {
            param($KnownSupportPhases)

            Assert-ReleasesJson {
                param($releasesJson)
                $releasesJson.'support-phase' | Should -BeIn $KnownSupportPhases
            }
        }
    }

    Context "'releases'" {

        It "releases.json exists for channel <ChannelVersion>" -TestCases @(
            @{ ChannelVersion = "5.0" }
            @{ ChannelVersion = "3.1" }
            @{ ChannelVersion = "3.0" }
            @{ ChannelVersion = "2.1" }
            @{ ChannelVersion = "2.2" }
            @{ ChannelVersion = "2.0" }
            @{ ChannelVersion = "1.1" }
            @{ ChannelVersion = "1.0" }
        ) {
            param($ChannelVersion)

            $releaseMetadatas
            | Where-Object { $PSItem.ChannelVersion -eq $ChannelVersion }
            | Should -HaveCount 1
        }

        It "Property '<PropertyName>' exists" -TestCases @(
            @{ PropertyName = 'release-version' }
            @{ PropertyName = 'release-date' }
        ) {
            param($PropertyName)

            Assert-ReleasesJsonEntry {
                param($release)
                Assert-HasMember $release $PropertyName
            }
        }

        It "Property '<PropertyName>' is not null or empty" -TestCases @(
            @{ PropertyName = 'release-version' }
            @{ PropertyName = 'release-date' }
        ) {
            param($PropertyName)

            Assert-ReleasesJsonEntry {
                param($release)
                $release.$PropertyName | Should -Not -BeNullOrEmpty
            }
        }

        It "Property 'release-date' is in format YYYY-MM-DD" {
            Assert-ReleasesJsonEntry {
                param($release)
                $release.'release-date' | Should -MatchExactly "^\d\d\d\d-\d\d-\d\d$"
            }
        }


        Context "'releases.sdk'" {

            It "Property '<PropertyName>' exists" -TestCases @(
                @{ PropertyName = 'version' }
                @{ PropertyName = 'files' }
            ) {
                param($PropertyName)

                Assert-ReleasesJsonEntry {
                    param($release)
                    Assert-HasMember $release.'sdk' $PropertyName
                }
            }

            It "Property '<PropertyName>' is not null or empty" -TestCases @(
                @{ PropertyName = 'version' }
                @{ PropertyName = 'files' }
            ) {
                param($PropertyName)

                Assert-ReleasesJsonEntry {
                    param($release)
                    $release.'sdk'.$PropertyName | Should -Not -BeNullOrEmpty
                }
            }

            Context "'releases.sdk.files'" {

                It "Property '<PropertyName>' exists" -TestCases @(
                    @{ PropertyName = 'name' }
                    @{ PropertyName = 'url' }
                    @{ PropertyName = 'hash' }
                ) {
                    param($PropertyName)

                    Assert-ReleasesJsonEntryFile -PackageType "sdk" {
                        param($file)
                        Assert-HasMember $file $PropertyName
                    }
                }

                It "Property '<PropertyName>' is not null or empty" -TestCases @(
                    @{ PropertyName = 'name' }
                    @{ PropertyName = 'url' }
                ) {
                    param($PropertyName)

                    Assert-ReleasesJsonEntryFile -PackageType "sdk" {
                        param($file)
                        $file.$PropertyName | Should -Not -BeNullOrEmpty
                    }
                }

                It "Property 'url' is a valid uri" {
                    Assert-ReleasesJsonEntryFile -PackageType "sdk" {
                        param($file)

                        $return = $null
                        $url = $file.'url'
                        $isUri = [System.Uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$return)
                        $isUri | Should -BeTrue
                    }
                }
            }
        }


        Context "'releases.runtime'" {

            It "Property '<PropertyName>' exists" -TestCases @(
                @{ PropertyName = 'version' }
                @{ PropertyName = 'files' }
            ) {
                param($PropertyName)

                Assert-ReleasesJsonEntry {
                    param($release)
                    if ($release.'runtime') {
                        Assert-HasMember $release.'runtime' $PropertyName
                    }
                }
            }

            It "Property '<PropertyName>' is not null or emtpy" -TestCases @(
                @{ PropertyName = 'version' }
                @{ PropertyName = 'files' }
            ) {
                param($PropertyName)

                Assert-ReleasesJsonEntry {
                    param($release)
                    if ($release.'runtime') {
                        $release.'runtime'.$PropertyName | Should -Not -BeNullOrEmpty
                    }

                }
            }

            Context "'releases.runtime.files'" {

                It "Property '<PropertyName>' exists" -TestCases @(
                    @{ PropertyName = 'name' }
                    @{ PropertyName = 'url' }
                    @{ PropertyName = 'hash' }
                ) {
                    param($PropertyName)

                    Assert-ReleasesJsonEntryFile -PackageType "runtime" {
                        param($file)
                        Assert-HasMember $file $PropertyName
                    }
                }

                It "Property '<PropertyName>' is not null or empty" -TestCases @(
                    @{ PropertyName = 'name' }
                    @{ PropertyName = 'url' }
                ) {
                    param($PropertyName)

                    Assert-ReleasesJsonEntryFile -PackageType "runtime" {
                        param($file)
                        $file.$PropertyName | Should -Not -BeNullOrEmpty
                    }
                }

                It "Property 'url' is a valid uri" {
                    Assert-ReleasesJsonEntryFile -PackageType "runtime" {
                        param($file)

                        $return = $null
                        $url = $file.'url'
                        $isUri = [System.Uri]::TryCreate($url, [System.UriKind]::Absolute, [ref]$return)
                        $isUri | Should -BeTrue
                    }
                }
            }
        }
    }
}


