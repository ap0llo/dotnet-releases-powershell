BeforeAll {
    . "$PSScriptRoot/_BeforeAll.ps1"
}

Describe "Get-DotNetReleaseInfo" {

    BeforeEach {
        # Default Mock: throw execption, all expected calls to Invoke-WebRequest should be mocked in the individual test cases
        Mock Invoke-WebRequest {
            throw "Unexpected call to Invoke-WebRequest with uri '$Uri'"
        }
    }

    Context "No Parameters" {

        It "Output is empty when release index contains no release channels" {

            # ARRANGE
            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                Get-ReleasesIndexResponse -Entries @()
            }

            # ACT
            $releaseInfo = Get-DotNetReleaseInfo

            # ASSERT
            $releaseInfo | Should -HaveCount 0
            Assert-MockCalled Invoke-WebRequest -Times 1
        }

        It "Output contains release metadata for every release channel listed in the release index" {

            # ARRANGE
            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                Get-ReleasesIndexResponse -Entries @(
                    Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "2.0" -ReleasesJsonUrl "http://example.com/2.0/releases.json"
                )
            }

            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                Get-ReleasesJsonResponse -ChannelVersion "1.0"
            }

            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "2.0" } {
                Get-ReleasesJsonResponse -ChannelVersion "2.0"
            }

            # ACT
            $releaseInfo = Get-DotNetReleaseInfo

            # ASSERT
            $releaseInfo | Should -HaveCount 0
            Assert-MockCalled Invoke-WebRequest -Times 3
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "2.0" } -Times 1
        }
    }

    Context "Parameter Set 'FromChannelInfo'" {

        It "Output contains release metadata for channel passed in as input" {

            # ARRANGE
            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                Get-ReleasesIndexResponse -Entries @(
                    Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "2.0" -ReleasesJsonUrl "http://example.com/2.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "3.0" -ReleasesJsonUrl "http://example.com/3.0/releases.json"
                )
            }

            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                Get-ReleasesJsonResponse -ChannelVersion "1.0"
            }

            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "3.0" } {
                Get-ReleasesJsonResponse -ChannelVersion "3.0"
            }

            # ACT
            $channels = Get-DotNetReleaseChannel
            $channels = $channels | Where-Object { ($PSItem.ChannelVersion -eq "1.0") -or ($PSItem.ChannelVersion -eq "3.0") }
            $releases = $channels | Get-DotNetReleaseInfo

            # ASSERT
            $releases | Should -HaveCount 0
            Assert-MockCalled Invoke-WebRequest -Times 3
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "2.0" } -Times 0
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "3.0" } -Times 1
        }

        # TODO: Check if the expected files for SDK and runtime are included in the output
    }

    Context "Parameter Set 'ChannelVersion'" {

        It "Output contains only release metadata for the specified channel version" {

            # ARRANGE
            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                Get-ReleasesIndexResponse -Entries @(
                    Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "2.0" -ReleasesJsonUrl "http://example.com/2.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "3.0" -ReleasesJsonUrl "http://example.com/3.0/releases.json"
                )
            }

            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "2.0" } {
                Get-ReleasesJsonResponse -ChannelVersion "2.0"
            }

            # ACT
            $releases = Get-DotNetReleaseInfo -ChannelVersion "2.0"

            # ASSERT
            $releases | Should -HaveCount 0
            Assert-MockCalled Invoke-WebRequest -Times 2
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } -Times 0
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "2.0" } -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "3.0" } -Times 0
        }

        It "Output is empty if specified channel version does not exist in the release index" {

            # ARRANGE
            Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                Get-ReleasesIndexResponse -Entries @(
                    Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    Get-ReleasesIndexEntry -ChannelVersion "2.0" -ReleasesJsonUrl "http://example.com/2.0/releases.json"
                )
            }

            # ACT
            $releases = Get-DotNetReleaseInfo -ChannelVersion "3.0"

            # ASSERT
            $releases | Should -HaveCount 0
            Assert-MockCalled Invoke-WebRequest -Times 1
            Assert-MockCalled Invoke-WebRequest -ParameterFilter { Test-ReleasesIndexUri $Uri } -Times 1
        }

        # TODO: Check if the expected files for SDK and runtime are included in the output
    }
}