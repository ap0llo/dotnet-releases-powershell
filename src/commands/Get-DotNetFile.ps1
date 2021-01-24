<#
.SYNOPSIS
    Downloads one or more .NET Core release files
.DESCRIPTION
    Get-DotNetFile downloads one or more .NET Core release files to the TEMP folder and returns the downloaded files as System.IO.FileInfo objects.
.PARAMETER FileInfo
    Specifies the file to download as file info object (as returned by Get-DotNetFileInfo).
    Accepts value from pipeline.
.PARAMETER ChannelVersion
    Limit files to download to a .NET Core release channel.
.PARAMETER ReleaseInfo
    Specifies the files to download as release info object (as returned by Get-DotNetFileReleaseInfo).
    Accepts value from pipeline.
.PARAMETER ReleaseVersion
    Limit files to download to a specific .NET Core release
.PARAMETER SdkVersion
    Limit files to download to the .NET Core release the specified version of the SDK belongs to.
.PARAMETER PackageType
    Limit files to download to either .NET Core Runtime or .NET Core SDK releases.
    Valid values are 'Runtime', 'Sdk' or 'All' (default)
.PARAMETER RuntimeIdentifier
    Limit files to download to files for a specific operating system.
.PARAMETER Extension
    Limit files to download to files with a specific file extension.
    E.g. Get the Windows installer files by limiting to 'exe'.
.EXAMPLE
    Get-DotNetFileInfo -SdkVersion 3.1.201 | Get-DotNetFile

    Get files using Get-DotNetFileInfo and pass to Get-DotNetFile as pipeline parameter
.EXAMPLE
    Get-DotNetFile -ReleaseVersion "3.1.2" -PackageType "Runtime" -Extension "exe" -RuntimeIdentifier "win-x64"

    Download the Windows 64bit installer of the .NET Core runtime 3.1.2
.EXAMPLE
    Get-DotNetFile

    Download all files from all .NET Core releases.
#>
function Get-DotNetFile {

    [CmdletBinding(DefaultParameterSetName = "FromFileInfo")]
    param (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromFileInfo")]
        [DotNetFileInfo[]]$FileInfo,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromReleaseInfo")]
        [DotNetReleaseInfo[]]$ReleaseInfo,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true, ParameterSetName = "FromChannelInfo")]
        [DotNetChannelInfo[]] $Channel,

        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [string]$ChannelVersion,

        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromReleaseInfo" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelInfo" )]
        [string]$ReleaseVersion,
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromReleaseInfo" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelInfo" )]
        [string]$SdkVersion,
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromReleaseInfo" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelInfo" )]
        [ValidateSet("Runtime", "Sdk", "All")]
        [string]$PackageType,
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromReleaseInfo" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelInfo" )]
        [string]$RuntimeIdentifier,
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelVersion" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromReleaseInfo" )]
        [Parameter( Mandatory = $false, ParameterSetName = "FromChannelInfo" )]
        [string]$Extension
    )

    BEGIN {
        $downloadDir = Join-Path ([System.IO.Path]::GetTempPath())  "dotnet-install_$([System.IO.Path]::GetRandomFileName())"
        Write-Verbose "Creating root output directory at '$downloadDir'"
        New-Item -ItemType Directory -Path $downloadDir | Out-Null
    }
    PROCESS {
        if (-not $PackageType) {
            $PackageType = "All"
        }

        switch ($PsCmdlet.ParameterSetName) {
            "FromFileInfo" {
                if (-not $FileInfo) {
                    $FileInfo = Get-DotNetFileInfo
                }
            }
            "FromChannelVersion" {
                $FileInfo = Get-DotNetFileInfo `
                    -ChannelVersion $ChannelVersion `
                    -ReleaseVersion $ReleaseVersion `
                    -SdkVersion $SdkVersion `
                    -PackageType $PackageType `
                    -RuntimeIdentifier $RuntimeIdentifier `
                    -Extension $Extension
            }
            "FromChannelInfo" {
                $FileInfo = Get-DotNetFileInfo `
                    -Channel $Channel `
                    -ReleaseVersion $ReleaseVersion `
                    -SdkVersion $SdkVersion `
                    -PackageType $PackageType `
                    -RuntimeIdentifier $RuntimeIdentifier `
                    -Extension $Extension
            }
            "FromReleaseInfo" {
                $FileInfo = Get-DotNetFileInfo `
                    -ReleaseInfo $ReleaseInfo `
                    -ReleaseVersion $ReleaseVersion `
                    -SdkVersion $SdkVersion `
                    -PackageType $PackageType `
                    -RuntimeIdentifier $RuntimeIdentifier `
                    -Extension $Extension
            }
            default {
                throw "Unexpected ParameterSetName '$($PsCmdlet.ParameterSetName)'"
            }
        }


        $totalFileCount = ($FileInfo | Measure-Object).Count
        $completedFileCount = 0
        $progressActivity = "Downloading Files"
        $progressActivityId = 1

        foreach ($file in $FileInfo) {

            $progessStepText = "Downloading $($file.Name), version $($file.Version)"
            $progressStatusText = "File $(($completedFileCount + 1).ToString().PadLeft($totalFileCount.Count.ToString().Length)) of $totalFileCount | $progessStepText"
            $progressPercentComplete = ($completedFileCount / $totalFileCount * 100)
            Write-Progress -Id $progressActivityId `
                -Activity $progressActivity `
                -Status $progressStatusText `
                -PercentComplete $progressPercentComplete `
                -CurrentOperation "Downloading file"


            $versionDir = Join-Path $downloadDir $file.Version
            if (-not (Test-Path $versionDir)) {
                Write-Verbose "Creating output directory for version '$($file.Version)' at '$versionDir'"
                New-Item -ItemType Directory -Path $versionDir | Out-Null
            }

            $ridDir = Join-Path $versionDir $file.RuntimeIdentifier
            if (-not (Test-Path $ridDir)) {
                Write-Verbose "Creating output directory for runtime identifier '$($file.RuntimeIdentifier)' at '$ridDir'"
                New-Item -ItemType Directory -Path $ridDir | Out-Null
            }

            $outPath = Join-Path $ridDir $file.Name
            if (Test-Path $outPath) {
                throw "Output path '$outPath' already exists"
            }
            Write-Verbose "Downloading file '$($file.Name)' to '$outPath'"
            Invoke-WebRequest -Uri $file.Url -OutFile $outPath -UseBasicParsing


            Write-Progress -Id $progressActivityId `
                -Activity $progressActivity `
                -Status $progressStatusText `
                -PercentComplete $progressPercentComplete `
                -CurrentOperation "Verifiyng hash"

            Write-Verbose "Verifying hash of downloaded file '$outPath'"
            $hash = (Get-FileHash -Path $outPath -Algorithm SHA512).Hash.ToLower()
            if ($hash -ne $file.Hash) {
                throw "Verification of hash failed. Expected: '$($file.Hash)', actual '$hash' (file '$outPath')"
            }
            else {
                Write-Verbose "Successfully verfified hash of '$outPath'"
            }
            # Pass downloaded file to pipeline
            Get-Item -Path $outPath

            $completedFileCount += 1
        }

        Write-Progress -Id 1 `
            -Activity $progressActivity `
            -Completed
    }
    END { }
}
