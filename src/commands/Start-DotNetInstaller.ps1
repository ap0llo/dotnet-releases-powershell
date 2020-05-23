<#
.SYNOPSIS
    Executes a .NET Core installer.
.DESCRIPTION
    Silently runs the installer for a .NET Core package.
    When run without admin privileges, a UAC prompt will appear during installation.
.PARAMETER InstallerPath
    The file path of the installer to run.
#>
function Start-DotNetInstaller {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateScript( { Test-Path $_ })]
        [string]
        $InstallerPath
    )

    $_logPath = Join-Path ([System.IO.Path]::GetTempPath()) "dotnet-install_$([System.IO.Path]::GetRandomFileName()).log"

    Write-Verbose "Running installer at '$InstallerPath', logging to '$_logPath'"

    $_process = Start-Process -FilePath $InstallerPath `
        -ArgumentList "/install", "/norestart", "/quiet", "/log", "$_logPath" `
        -NoNewWindow `
        -PassThru `
        -Wait `

    if ($_process.ExitCode -ne 0) {
        throw "Failed to run .NET installer '$InstallerPath'. Installer completed with exit code $($_process.ExitCode). Log file can be found at '$_logPath'"
    }
}
