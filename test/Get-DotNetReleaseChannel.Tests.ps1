BeforeAll {
    . "$PSScriptRoot/_BeforeAll.ps1"
}

Describe "Get-DotNetReleaseChannel" {

    BeforeEach {
        # Default Mock: throw execption, all expected calls to Invoke-WebRequest should be mocked in the individual test cases
        Mock Invoke-WebRequest {
            throw "Unexpected call to Invoke-WebRequest with uri '$Uri'"
        }
    }

    It "Returns an empty result if there are no releases" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries @()
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel

        # ASSERT
        $releaseChannels | Should -HaveCount 0
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }

    It "Returns all channels if not parameters are specified" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries (Get-ReleasesIndexEntry -ChannelVersion "5.0"), (Get-ReleasesIndexEntry -ChannelVersion "3.1")
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel

        # ASSERT
        $releaseChannels | Should -HaveCount 2
        $releaseChannels | Where-Object { $PSItem.ChannelVersion -eq "5.0" } | Should -HaveCount 1
        $releaseChannels | Where-Object { $PSItem.ChannelVersion -eq "3.1" } | Should -HaveCount 1
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }

    It "Correctly loads release channel information" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            $entry = Get-ReleasesIndexEntry `
                -ChannelVersion "5.0" `
                -LatestRelease "5.0.0-rc.2" `
                -LatestReleaseDate "2020-10-13" `
                -SupportPhase "rc" `
                -ReleasesJsonUrl "https://example.com/dotnet/release-metadata/5.0/releases.json"
            Get-ReleasesIndexResponse -Entries $entry
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel

        # ASSERT
        $releaseChannels | Should -HaveCount 1
        $releaseChannels[0].ChannelVersion | Should -BeExactly "5.0"
        $releaseChannels[0].LatestRelease | Should -BeExactly "5.0.0-rc.2"
        $releaseChannels[0].LatestReleaseDate | Should -BeExactly (Get-Date -Year 2020 -Month 10 -Day 13).Date
        $releaseChannels[0].SupportPhase | Should -BeExactly "rc"
        $releaseChannels[0].ReleasesJsonUri | Should -BeExactly "https://example.com/dotnet/release-metadata/5.0/releases.json"
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }

    It "Does not require eol-date to be set" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries @(
                (Get-ReleasesIndexEntry -ChannelVersion "2.0" -EolDate $null),
                (Get-ReleasesIndexEntry -ChannelVersion "1.0" -EolDate "2020-11-08")
            )
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel

        # ASSERT
        $releaseChannels | Should -HaveCount 2
        $releaseChannels[0].EolDate | Should -Be $null
        $releaseChannels[1].EolDate | Should -BeExactly (Get-Date -Year 2020 -Month 11 -Day 8).Date
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }

    It "Returns filtered result when channel version is specified" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries @(
                (Get-ReleasesIndexEntry -ChannelVersion "1.0"),
                (Get-ReleasesIndexEntry -ChannelVersion "2.0")
            )
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel -ChannelVersion "2.0"

        # ASSERT
        $releaseChannels | Should -HaveCount 1
        $releaseChannels[0].ChannelVersion | Should -BeExactly "2.0"
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }

    It "Returns empty result when specified channel version is not found" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries @(
                (Get-ReleasesIndexEntry -ChannelVersion "1.0"),
                (Get-ReleasesIndexEntry -ChannelVersion "2.0")
            )
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel -ChannelVersion "4.0"

        # ASSERT
        $releaseChannels | Should -HaveCount 0
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }


    It "Returns filtered result when support phase is specified" {

        # ARRANGE
        Mock Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Verifiable {
            Get-ReleasesIndexResponse -Entries @(
                (Get-ReleasesIndexEntry -ChannelVersion "1.0" -SupportPhase "eol"),
                (Get-ReleasesIndexEntry -ChannelVersion "2.0" -SupportPhase "lts")
            )
        }

        # ACT
        $releaseChannels = Get-DotNetReleaseChannel -SupportPhase "lts"

        # ASSERT
        $releaseChannels | Should -HaveCount 1
        $releaseChannels[0].ChannelVersion | Should -BeExactly "2.0"
        Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
    }
}