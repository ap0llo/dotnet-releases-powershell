BeforeAll {
    . "$PSScriptRoot/_BeforeAll.ps1"
}

Describe "Get-DotNetReleaseType" {

    Context "No Parameters" {

        It "Outputs all possible values" {

            # ACT
            $releaseTypes = Get-DotNetReleaseType

            # ASSERT
            $releaseTypes | Should -HaveCount 2
            $releaseTypes | Should -Contain "LTS"
            $releaseTypes | Should -Contain "STS"            
        }

       
    }

    Context "ReleaseType parameter set" {

        It "Parses the specified release type value"  -TestCases @(
            @{ 
                Value    = 'sts' 
                Expected = "STS"
            }
            @{ 
                Value    = 'lts' 
                Expected = "LTS"
            }            
        ) {
            param($Value, $Expected)

            # ACT
            $actual = Get-DotNetReleaseType -ReleaseType $Value

            # ASSERT
            $actual | Should -HaveCount 1
            $actual.GetType().Name | Should -BeExactly "DotNetReleaseType"
            $actual | Should -Be $Expected
        }
    }

    It "Throws if release-type has unexpected value of '<InvalidReleaseType>'" -TestCase @(
        @{InvalidReleaseType = "not-a-release-type" }
    ) {

        param($InvalidReleaseType)

        # ACT / ASSERT
        { Get-DotNetReleaseType -ReleaseType $InvalidReleaseType } | Should -Throw "Cannot parse value '$InvalidReleaseType' as DotNetReleaseType"
    }
}