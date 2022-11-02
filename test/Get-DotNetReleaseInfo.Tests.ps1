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

    Context "Output data" {

        Context "SupportPhase" {

            It "A support-phase value of '<SupportPhase>' is correctly parsed" -TestCase @(
                @{ SupportPhase = "preview" }
                @{ SupportPhase = "go-live" }
                @{ SupportPhase = "active" }
                @{ SupportPhase = "maintenance" }
                @{ SupportPhase = "eol" }
            ) {

                param($SupportPhase)

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -SupportPhase $SupportPhase `
                        -Entries @(Get-ReleasesJsonEntry)
                }


                # ACT
                $release = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $release | Should -HaveCount 1
                $release[0].SupportPhase | Should -Be (Get-DotNetSupportPhase $SupportPhase)
            }


            It "Throws if support-phase has unexpected value of '<InvalidSupportPhase>'" -TestCase @(        
                @{InvalidSupportPhase = "not-a-support-phase" }
            ) {

                param($InvalidSupportPhase)

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -SupportPhase $InvalidSupportPhase `
                        -Entries @(Get-ReleasesJsonEntry)
                }


                # ACT / ASSERT
                { Get-DotNetReleaseInfo } | Should -Throw "Cannot parse value '$InvalidSupportPhase' as DotNetSupportPhase*"
            }

        }

        Context "'sdk' metadata" {

            It "Output includes the SDK metadata from the releases.json file" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry `
                            -ReleaseVersion "1.2.0" `
                            -Sdk (
                            Get-ReleasesJsonSdkEntry `
                                -Version "1.2.3" `
                                -Files @(
                                Get-ReleasesJsonFileEntry `
                                    -Name "some-file.zip" `
                                    -Rid "win-x86" `
                                    -Url "https://www.example.com/some-file.zip" `
                                    -Hash "def345"
                            )))
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Sdk | Should -Not -BeNull
                $releases[0].Sdk.ReleaseVersion | Should -BeExactly "1.2.0"
                $releases[0].Sdk.Version | Should -BeExactly "1.2.3"
                $releases[0].Sdk.Files | Should -HaveCount 1

                $releases[0].Sdk.Files[0].PackageType | Should -BeExactly "Sdk"
                $releases[0].Sdk.Files[0].ReleaseVersion | Should -BeExactly "1.2.0"
                $releases[0].Sdk.Files[0].Version | Should -BeExactly "1.2.3"
                $releases[0].Sdk.Files[0].Name | Should -BeExactly "some-file.zip"
                $releases[0].Sdk.Files[0].Extension | Should -BeExactly "zip"
                $releases[0].Sdk.Files[0].RuntimeIdentifier | Should -BeExactly "win-x86"
                $releases[0].Sdk.Files[0].Url | Should -BeExactly "https://www.example.com/some-file.zip"
                $releases[0].Sdk.Files[0].Hash | Should -BeExactly "def345"
            }

            It "'Files' can be empty" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry -Sdk (Get-ReleasesJsonSdkEntry -Version "1.2.3" -Files @())
                    )
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Sdk | Should -Not -BeNull
                $releases[0].Sdk.Files | Should -HaveCount 0
            }

            It "The 'Sdk' property is null if the release does not contain a sdk" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry -Sdk $null
                    )
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Sdk | Should -BeNull
            }
        }

        Context "'runtime' metadata" {

            It "Output includes the runtime metadata from the releases.json file" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry `
                            -ReleaseVersion "1.2.0" `
                            -Runtime (
                            Get-ReleasesJsonRuntimeEntry `
                                -Version "1.2.3" `
                                -Files @(
                                Get-ReleasesJsonFileEntry `
                                    -Name "some-file.zip" `
                                    -Rid "win-x86" `
                                    -Url "https://www.example.com/some-file.zip" `
                                    -Hash "def345"
                            )))
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Runtime | Should -Not -BeNull
                $releases[0].Runtime.ReleaseVersion | Should -BeExactly "1.2.0"
                $releases[0].Runtime.Version | Should -BeExactly "1.2.3"
                $releases[0].Runtime.Files | Should -HaveCount 1

                $releases[0].Runtime.Files[0].PackageType | Should -BeExactly "Runtime"
                $releases[0].Runtime.Files[0].ReleaseVersion | Should -BeExactly "1.2.0"
                $releases[0].Runtime.Files[0].Version | Should -BeExactly "1.2.3"
                $releases[0].Runtime.Files[0].Name | Should -BeExactly "some-file.zip"
                $releases[0].Runtime.Files[0].Extension | Should -BeExactly "zip"
                $releases[0].Runtime.Files[0].RuntimeIdentifier | Should -BeExactly "win-x86"
                $releases[0].Runtime.Files[0].Url | Should -BeExactly "https://www.example.com/some-file.zip"
                $releases[0].Runtime.Files[0].Hash | Should -BeExactly "def345"
            }

            It "'Files' can be empty" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry -Runtime (Get-ReleasesJsonSdkEntry -Version "1.2.3" -Files @())
                    )
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Runtime | Should -Not -BeNull
                $releases[0].Runtime.Files | Should -HaveCount 0
            }


            It "The 'Runtime' property if null is the release does not contain a runtime" {

                # ARRANGE
                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesIndexUri $Uri } {
                    Get-ReleasesIndexResponse -Entries @(
                        Get-ReleasesIndexEntry -ChannelVersion "1.0" -ReleasesJsonUrl "http://example.com/1.0/releases.json"
                    )
                }

                Mock Invoke-WebRequest -Verifiable -ParameterFilter { Test-ReleasesJsonUri $Uri -ChannelVersion "1.0" } {
                    Get-ReleasesJsonResponse `
                        -ChannelVersion "1.0" `
                        -Entries @(
                        Get-ReleasesJsonEntry -Runtime $null
                    )
                }

                # ACT
                $releases = Get-DotNetReleaseInfo -ChannelVersion "1.0"

                # ASSERT
                $releases | Should -HaveCount 1
                $releases[0].Runtime | Should -BeNull
            }
        }
    }

}