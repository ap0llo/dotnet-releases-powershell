# See https://github.com/dotnet/core/tree/master/release-notes
$ReleaseIndexUri = "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"

class DotNetChannelInfo {

    [ValidateNotNullOrEmpty()][string]$ChannelVersion
    [ValidateNotNullOrEmpty()][string]$LatestRelease
    [DateTime]$LatestReleaseDate
    [ValidateNotNull()][Uri]$ReleasesJsonUri

    DotNetChannelInfo(
        [string]$ChannelVersion,
        [string]$LatestRelease,
        [DateTime]$LatestReleaseDate,
        [Uri]$ReleasesJsonUri) {
       $this.ChannelVersion = $ChannelVersion
       $this.LatestRelease = $LatestRelease
       $this.LatestReleaseDate = $LatestReleaseDate
       $this.ReleasesJsonUri = $ReleasesJsonUri
    }
}


class DotNetReleaseInfo {

    [ValidateNotNullOrEmpty()][string]$ChannelVersion
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][DateTime]$ReleaseDate
    [DotNetRuntimeReleaseInfo]$Runtime
    [DotNetSdkReleaseInfo]$Sdk

    DotNetReleaseInfo(
        [string]$ChannelVersion,
        [string]$Version,
        [DateTime]$ReleaseDate,
        [DotNetRuntimeReleaseInfo]$Runtime,
        [DotNetSdkReleaseInfo]$Sdk
    ) {
        $this.ChannelVersion = $ChannelVersion
        $this.Version = $Version
        $this.ReleaseDate = $ReleaseDate
        $this.Runtime = $Runtime
        $this.Sdk = $Sdk
    }
}

class DotNetRuntimeReleaseInfo {

    [ValidateNotNullOrEmpty()][string]$ReleaseVersion
    [string]$Version
    [DotNetFileInfo[]]$Files

    DotNetRuntimeReleaseInfo(
        [string]$ReleaseVersion,
        [string]$Version,
        [DotNetFileInfo[]]$Files
    ) {
        $this.ReleaseVersion = $ReleaseVersion
        $this.Version = $Version
        $this.Files = $Files
    }
}

class DotNetSdkReleaseInfo {

    [ValidateNotNullOrEmpty()][string]$ReleaseVersion
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNull()][DotNetFileInfo[]]$Files

    DotNetSdkReleaseInfo(
        [string]$ReleaseVersion,
        [string]$Version,
        [DotNetFileInfo[]]$Files
    ) {
        $this.ReleaseVersion = $ReleaseVersion
        $this.Version = $Version
        $this.Files = $Files
    }
}

class DotNetFileInfo {

    [ValidateNotNullOrEmpty()][ValidateSet("Runtime","Sdk")][string]$PackageType
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][string]$ReleaseVersion
    [ValidateNotNullOrEmpty()][string]$Name
    [ValidateNotNull()][string]$Extension
    [ValidateNotNull()][string]$RuntimeIdentifier
    [ValidateNotNullOrEmpty()][Uri]$Url
    [string]$Hash


    DotNetFileInfo(
        [string]$PackageType,
        [string]$Version,
        [string]$ReleaseVersion,
        [string]$Name,
        [string]$Extension,
        [string]$RuntimeIdentifier,
        [Uri]$Url,
        [string]$Hash
    ) {
        $this.PackageType = $PackageType
        $this.Version = $Version
        $this.ReleaseVersion = $ReleaseVersion
        $this.Name = $Name
        $this.Extension = $Extension
        $this.RuntimeIdentifier = $RuntimeIdentifier
        $this.Url = $Url
        $this.Hash = $Hash
    }
}

function Get-DotNetReleaseChannel {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)][string]$ChannelVersion
    )


    $response = Invoke-WebRequest -Uri $ReleaseIndexUri
    $releaseIndex = $response.Content | ConvertFrom-Json


    foreach($obj in $releaseIndex.'releases-index') {

        $channelInfo = [DotNetChannelInfo]::new(
            $obj.'channel-version',
            $obj.'latest-release',
            [DateTime]::Parse($obj.'latest-release-date'),
            $obj.'releases.json'
        )

        # Return channel info to pipeline
        if((-not $ChannelVersion) -or ($channelInfo.ChannelVersion -eq $ChannelVersion)) {
            $channelInfo
        }
    }

}


function Get-DotNetReleaseInfo {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ParameterSetName= "FromChannelInfo")]
        [ValidateNotNull()]
        [DotNetChannelInfo[]] $Channel,

        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelVersion")]
        [string]$ChannelVersion,

        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelInfo")]
        [string]$ReleaseVersion,
        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelInfo")]
        [string]$SdkVersionVersion,
        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelVersion")]
        [Parameter(Mandatory=$false, ParameterSetName = "FromChannelInfo")]
        [switch]$Latest
    )

    BEGIN { }
    PROCESS {

        function GetFileInfos($packageType, $version, $thisReleaseVersion, $jsonFilesArray) {
            foreach($jsonObject in $jsonFilesArray) {
                $name = $jsonObject.'name'
                $fileInfo = [DotNetFileInfo]::new(
                    $packageType,
                    $version,
                    $thisReleaseVersion,
                    $name,
                    [System.IO.Path]::GetExtension($name).Trim("."),
                    $jsonObject.'rid',
                    [Uri]$jsonObject.'url',
                    $jsonObject.'hash'
                )

                #return to pipeline
                $fileInfo
            }
        }

        function GetRuntimeReleaseInfo($thisReleaseVersion, $runtimeJsonObject) {
            Write-Verbose "Reading runtime info for version '$thisReleaseVersion'"
            $version = $runtimeJsonObject.'version'
            $runtimeFiles = GetFileInfos -packageType "Runtime" -version $version -thisReleaseVersion $thisReleaseVersion -jsonFilesArray $runtimeJsonObject.'files'
            return [DotNetRuntimeReleaseInfo]::new(
                $thisReleaseVersion,
                $version,
                $runtimeFiles
            )
        }

        function GetSdkReleaseInfo($thisReleaseVersion, $sdkJsonObject) {
            Write-Verbose "Reading SDK info for version '$thisReleaseVersion'"
            $version = $sdkJsonObject.'version'
            $sdkFiles = GetFileInfos -packageType "Sdk" -version $version -thisReleaseVersion $thisReleaseVersion -jsonFilesArray $sdkJsonObject.'files'
            return [DotNetSdkReleaseInfo]::new(
                $thisReleaseVersion,
                $version,
                $sdkFiles
            )
        }

        if(-not $Channel) {
            $Channel = Get-DotNetReleaseChannel -ChannelVersion $ChannelVersion
        }

        foreach($channelInfo in $Channel) {

            Write-Verbose "Getting release infos for channel '$($channelInfo.ChannelVersion)'"

            $response = Invoke-WebRequest -Uri $channelInfo.ReleasesJsonUri
            $releaseInfoJson = $response.Content | ConvertFrom-Json

            $latestRelease = $releaseInfoJson.'latest-release'

            foreach($releaseJson in $releaseInfoJson.'releases') {

                $thisReleaseVersion = $releaseJson.'release-version'

                Write-Verbose "Reading release info for version '$thisReleaseVersion' "

                $runtimeInfo = GetRuntimeReleaseInfo $thisReleaseVersion $releaseJson.'runtime'
                $sdkInfo = GetSdkReleaseInfo $thisReleaseVersion $releaseJson.'sdk'

                $releaseInfo = [DotNetReleaseInfo]::new(
                    $channelInfo.ChannelVersion,
                    $thisReleaseVersion,
                    [DateTime]::Parse($releaseJson.'release-date'),
                    $runtimeInfo,
                    $sdkInfo
                )

                if($ReleaseVersion -and ($releaseInfo.Version -ne $ReleaseVersion)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because it does not match the value of the '-ReleaseVersion' parameter"
                    continue
                }

                if($Latest -and ($releaseInfo.Version -ne $latestRelease)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because it is not the latest release and the  '-Latest' switch was set"
                    continue
                }

                if($SdkVersionVersion -and ($releaseInfo.Sdk.Version -ne $SdkVersionVersion)) {
                    Write-Verbose "Ignoring release '$($releaseInfo.Version)' because the SDK version '$($releaseInfo.Sdk.Version)' does not match the value of the '-SdkVersion' parameter"
                    continue
                }

                # Return release info to pipeline
                $releaseInfo
            }
        }
    }
    END {}
}



function Get-DotNetFileInfo {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$ChannelVersion,
        [Parameter(Mandatory = $false)][string]$ReleaseVersion,
        [Parameter(Mandatory = $false)][string]$SdkVersion,
        [Parameter(Mandatory = $false)][ValidateSet("Runtime", "Sdk", "All")] [string]$PackageType,
        [Parameter(Mandatory = $false)] [string]$RuntimeIdentifier,
        [Parameter(Mandatory = $false)] [string]$Extension
    )

    # When no PackageType is set, default to "All"
    if(-not $PackageType) {
        $PackageType = "All"
    }

    # Get channel (pass in ChannelVersion to limit result)
    $channelInfo = Get-DotNetReleaseChannel -ChannelVersion $ChannelVersion

    # Get all release infos for all channels
    $releaseInfos = $channelInfo | Get-DotNetReleaseInfo -ReleaseVersion $ReleaseVersion -SdkVersion $SdkVersion

    # Get files from release infos
    $files = @()
    # Include Runtime files
    $files +=  @($releaseInfos | Select-Object -ExpandProperty Runtime | Select-Object -ExpandProperty Files)
    # Include SDK files
    $files +=  @($releaseInfos | Select-Object -ExpandProperty Sdk | Select-Object -ExpandProperty Files)

    # When set, filter files based on package type
    if($PackageType -ne "all") {
        $files = $files | Where-Object -FilterScript { $PSItem.PackageType -eq $PackageType }
    }

    # when specified, filter files by runtime identifier
    if($RuntimeIdentifier) {
        $files = $files | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $RuntimeIdentifier }
    }

    # when specified, filter files by file extension
    if($Extension) {
        $files = $files | Where-Object -FilterScript { $PSItem.Extension -eq $Extension }
    }

    return $files
}


function Get-DotNetFile {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ParameterSetName = "FromFileInfo")][DotNetFileInfo[]]$FileInfo,

        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )][string]$ChannelVersion,
        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )][string]$ReleaseVersion,
        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )][string]$SdkVersion,
        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )][ValidateSet("Runtime", "Sdk", "All")] [string]$PackageType,
        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )] [string]$RuntimeIdentifier,
        [Parameter( Mandatory = $false, ParameterSetName = "FromQueryParameters" )] [string]$Extension
    )

    BEGIN {
        $downloadDir = Join-Path ([System.IO.Path]::GetTempPath())  "dotnet-install_$([System.IO.Path]::GetRandomFileName())"
        Write-Verbose "Creating root output directory at '$downloadDir'"
        New-Item -ItemType Directory -Path $downloadDir | Out-Null
    }
    PROCESS {

        if(-not $PackageType) {
            $PackageType = "All"
        }

        if(-not $FileInfo) {
            $FileInfo = Get-DotNetFileInfo -ChannelVersion $ChannelVersion `
                                           -ReleaseVersion $ReleaseVersion `
                                           -SdkVersion $SdkVersion `
                                           -PackageType $PackageType `
                                           -RuntimeIdentifier $RuntimeIdentifier `
                                           -Extension $Extension
        }

        foreach($file in $FileInfo) {
            $versionDir = Join-Path $downloadDir $file.Version
            if(-not (Test-Path $versionDir)) {
                Write-Verbose "Creating output directory for version '$($file.Version)' at '$versionDir'"
                New-Item -ItemType Directory -Path $versionDir | Out-Null
            }

            $ridDir = Join-Path $versionDir $file.RuntimeIdentifier
            if(-not (Test-Path $ridDir)) {
                Write-Verbose "Creating output directory for runtime identifider '$($file.VerRuntimeIdentifiersion)' at '$ridDir'"
                New-Item -ItemType Directory -Path $ridDir | Out-Null
            }

            $outPath = Join-Path $ridDir $file.Name
            if(Test-Path $outPath) {
                throw "Output path '$outPath' already exists"
            }
            Write-Verbose "Downloading file '$($file.Name)' to '$outPath'"
            Invoke-WebRequest -Uri $file.Url -OutFile $outPath

            Write-Verbose "Verifying hash of downloaded file '$outPath'"
            $hash = (Get-FileHash -Path $outPath -Algorithm SHA512).Hash.ToLower()
            if($hash -ne $file.Hash) {
                throw "Verification of hash failed. Expected: '$($file.Hash)', actual '$hash' (file '$outPath')"
            } else {
                Write-Verbose "Successfully verfified hash of '$outPath'"
            }

            # Pass downloaded file to pipeline
            Get-Item -Path $outPath
        }
     }
    END { }
}



function Install-DotNet {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "FromReleaseVersion")]
        [Parameter(Mandatory = $true, ParameterSetName = "FromDotNetReleaseInfo")]
        [ValidateSet("Runtime", "Sdk")] 
        [string]$PackageType,

        [Parameter(Mandatory = $true, ParameterSetName = "FromReleaseVersion")][string]$ReleaseVersion,

        [Parameter(Mandatory = $true, ParameterSetName = "FromSdkVersion")][string]$SdkVersion,

        [Parameter(Mandatory = $true, ParameterSetName = "FromDotNetReleaseInfo")]
        [ValidateNotNull()]
        [DotNetReleaseInfo]$ReleaseInfo
    )


    function GetRid {
        # Determine runtime identifier for current OS
        
        $platform = [System.Environment]::OSVersion.Platform
        switch($platform) {
            "Win32NT" {
                if([System.Environment]::Is64BitOperatingSystem) {
                    return "win-x64"
                } else {
                    return "win-x86"
                }
            }
            default {
                throw "Unimplemented platform '$platform'"
            }
        }
    }

    $_runtimeIdentifier = GetRid

    Write-Verbose "Determined current Runtime Identifier to be '$_runtimeIdentifier'"

    $_files = @()

    Write-Verbose "ParameterSetName is '$($PsCmdlet.ParameterSetName)', PackageType is '$PackageType' "
    switch ($PsCmdlet.ParameterSetName) {
        "FromReleaseVersion" {
            $_files = Get-DotNetFileInfo -RuntimeIdentifier $_runtimeIdentifier `
                                         -ReleaseVersion $ReleaseVersion `
                                         -PackageType $PackageType `
                                         -Extension "exe"
        }
        "FromSdkVersion" {
            $PackageType = "Sdk"
            $_files = Get-DotNetFileInfo -RuntimeIdentifier $_runtimeIdentifier `
                                         -SdkVersion $SdkVersion `
                                         -PackageType $PackageType `
                                         -Extension "exe"
            
        }
        "FromDotNetReleaseInfo"{

            switch ($PackageType) {
                "Sdk" {                    
                    $_files = $ReleaseInfo.Sdk.Files `
                        | Where-Object -FilterScript { $PSItem.Extension -eq "exe" } `
                        | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $_runtimeIdentifier }
                }
                "Runtime" {
                    $_files = $ReleaseInfo.Runtime.Files `
                        | Where-Object -FilterScript { $PSItem.Extension -eq "exe" } `
                        | Where-Object -FilterScript { $PSItem.RuntimeIdentifier -eq $_runtimeIdentifier }

                }
                default {
                    throw "Unexpected package type '$PackageType'"
                }
            }
        } 
        default {
            throw "Unexpected ParameterSetName '$($PsCmdlet.ParameterSetName)'"
        }
    }

    $_count = ($_files | Measure-Object).Count
    
    if($_count -eq 0) {
        throw "Failed to find a matching installer"
    }
    if($_count -gt 1) {
        throw "Found multiple installers matching the specified criteria"
    }
    
    if(Test-DotNetInstallation -PackageType $PackageType -Version $_files.Version) {
        throw ".NET $PackageType, version $($_files.Version) is already installed"
    } else {

        Write-Verbose "Installing .NET $($_files.PackageType), version $($_files.Version)"
        $_installerFile = Get-DotNetFile -FileInfo $_files
        Start-DotNetInstaller -InstallerPath $_installerFile.FullName

        Write-Verbose "Deleting temporary installer file '$($_installerFile.FullName)'"
        try {
            Remove-Item -Path $_installerFile.FullName
        }
        catch {
            # Ignore errors
        }
    }
}

function Start-DotNetInstaller {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_})]
        [string]
        $InstallerPath
    )

    $_logPath = Join-Path ([System.IO.Path]::GetTempPath()) "dotnet-install_$([System.IO.Path]::GetRandomFileName()).log"

    Write-Verbose "Running installer at '$InstallerPath', logging to '$_logPath'"

    $_process = Start-Process -FilePath $InstallerPath `
                              -ArgumentList "/install","/norestart","/quiet","/log","$_logPath" `
                              -NoNewWindow `
                              -PassThru `
                              -Wait `

    if($_process.ExitCode -ne 0) {
        throw "Failed to run .NET installer '$InstallerPath'. Installer completed with exit code $($_process.ExitCode). Log file can be found at '$_logPath'"
    }
}


class DotNetInstallation {

    [ValidateNotNullOrEmpty()][string]$PackageType
    [string]$Name
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][string]$Location

    DotNetInstallation(
        [string]$PackageType,
        [string]$Name,
        [string]$Version,
        [string]$Location
    ) {
        $this.PackageType = $PackageType
        $this.Name = $Name
        $this.Version = $Version
        $this.Location = $Location
    }
}

function Get-DotNetInstallation {

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][ValidateSet("Runtime","Sdk","All")][string]$PackageType
    )

    # If no PackageType was specified, default to "All"
    if(-not $PackageType) {
        $PackageType = "All"
    }


    $dotNetCommand = Get-Command -Name "dotnet" -CommandType Application
    if(-not $dotNetCommand) {
        return
    }

    # Get SDK installations
    if(($PackageType -eq "Sdk") -or ($PackageType -eq "All")) {

        $command = "dotnet --list-sdks"
        $output = Invoke-Expression $command
        if($LASTEXITCODE -ne 0) {
            throw "Command '$command' completed with exit code $LASTEXITCODE"
        }

        # dotnet --list-sdks returns runtimes in the Format
        # VERSION [LOCATION], e.g.
        # 3.1.101 [C:\Program Files\dotnet\sdk]
        foreach($outputLine in $output) {
            if(-not $outputLine.Contains("[")) {
                continue
            }

            $_index = $outputLine.IndexOf("[")
            $_version = $outputLine.Substring(0, $_index).Trim()
            $_location = $outputLine.Substring($_index).Trim().Trim('[',']')

            $installation = [DotNetInstallation]::new(
                "Sdk",
                "",
                $_version,
                $_location
            )

            # output value to pipeline
            $installation
        }
    }


    # Get Runtime installations
    if(($PackageType -eq "Runtime") -or ($PackageType -eq "All")) {

        $command = "dotnet --list-runtimes"
        $output = Invoke-Expression $command
        if($LASTEXITCODE -ne 0) {
            throw "Command '$command' completed with exit code $LASTEXITCODE"
        }

        # dotnet --list-runtimes returns runtimes in the Format
        # NAME VERSION [LOCATION], e.g.
        # Microsoft.AspNetCore.All 2.1.11 [C:\Program Files\dotnet\shared\Microsoft.AspNetCore.All]

        foreach($outputLine in $output) {
            if(-not $outputLine.Contains("[")) {
                continue
            }

            $_bracketIndex = $outputLine.IndexOf("[")
            $_nameAndVersion = $outputLine.Substring(0, $_bracketIndex).Trim()
            $_location = $outputLine.Substring($_bracketIndex).Trim().Trim('[',']')

            if(-not $_nameAndVersion.Contains(" ")) {
                continue
            }

            $_spaceIndex = $_nameAndVersion.IndexOf(" ")
            $_name = $_nameAndVersion.Substring(0, $_spaceIndex).Trim()
            $_version = $_nameAndVersion.Substring($_spaceIndex).Trim()

            $installation = [DotNetInstallation]::new(
                "Runtime",
                $_name,
                $_version,
                $_location
            )

            # output value to pipeline
            $installation
        }
    }
}


function Test-DotNetInstallation {
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][ValidateSet("Runtime","Sdk","All")][string]$PackageType,
        [Parameter(Mandatory=$false)][string]$Version
    )

    # If no PackageType was specified, default to "All"
    if(-not $PackageType) {
        $PackageType = "All"
    }


    $installations = Get-DotNetInstallation -PackageType $PackageType

    if($Version) {
        $installations = $installations | Where-Object -FilterScript { $PSItem.Version -eq $Version }
    }

    $count = ($installations | Measure-Object).Count
    return ($count -gt 0)
}

