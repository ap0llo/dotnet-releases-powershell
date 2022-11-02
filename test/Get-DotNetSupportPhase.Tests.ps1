BeforeAll {
    . "$PSScriptRoot/_BeforeAll.ps1"
}

Describe "Get-DotNetSupportPhase" {

    Context "No Parameters" {

        It "Output  all possible support phase values" {

            # ACT
            $supportPhases = Get-DotNetSupportPhase

            # ASSERT
            $supportPhases | Should -HaveCount 5
            $supportPhases | Should -Contain "Preview"
            $supportPhases | Should -Contain "GoLive"
            $supportPhases | Should -Contain "Active"
            $supportPhases | Should -Contain "Maintenance"
            $supportPhases | Should -Contain "EOL"
        }

       
    }

    Context "SupportPhase parameter set" {

        It "Parses the specified support phase value"  -TestCases @(
            @{ 
                Value    = 'preview' 
                Expected = "Preview"
            }
            @{ 
                Value    = 'go-live' 
                Expected = "GoLive"
            }
            @{ 
                Value    = 'active' 
                Expected = "Active"
            }
            @{ 
                Value    = 'maintenance' 
                Expected = "Maintenance"
            }
            @{ 
                Value    = 'eol' 
                Expected = "EOL"
            }
        ) {
            param($Value, $Expected)

            # ACT
            $actual = Get-DotNetSupportPhase -SupportPhase $Value

            # ASSERT
            $actual | Should -HaveCount 1
            $actual.GetType().Name | Should -BeExactly "DotNetSupportPhase"
            $actual | Should -Be $Expected
        }
    }

    It "Throws if support-phase has unexpected value of '<InvalidSupportPhase>'" -TestCase @(
        @{InvalidSupportPhase = "not-a-support-phase" }
    ) {

        param($InvalidSupportPhase)

        # ACT / ASSERT
        { Get-DotNetSupportPhase -SupportPhase $InvalidSupportPhase } | Should -Throw "Cannot parse value '$InvalidSupportPhase' as DotNetSupportPhase"
    }
}