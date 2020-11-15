# Install Pester
$pesterVersion = "5.0.4"
if((Get-Module -Name "Pester").Version -ne $pesterVersion) {

    Write-Host "Installing Pester version $pesterVersion"
    Remove-Module Pester -Force -ErrorAction SilentlyContinue
    Install-Module Pester -Force -RequiredVersion $pesterVersion
    Import-Module Pester -RequiredVersion $pesterVersion
}

# Run Tests
$testsDirectory = (Join-Path $PSScriptRoot "../test" | Resolve-Path).Path
Invoke-Pester -Path $testsDirectory -Output Detailed