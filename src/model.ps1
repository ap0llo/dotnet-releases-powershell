enum DotNetSupportPhase {
    Preview
    EOL
    LTS
    Maintenance
    RC
    Current
}

class DotNetChannelInfo {

    [ValidateNotNullOrEmpty()][string]$ChannelVersion
    [ValidateNotNullOrEmpty()][string]$LatestRelease
    [DateTime]$LatestReleaseDate
    [ValidateNotNull()][Uri]$ReleasesJsonUri
    [Nullable[DateTime]]$EolDate
    [ValidateNotNull()][DotNetSupportPhase]$SupportPhase

    DotNetChannelInfo(
        [string]$ChannelVersion,
        [string]$LatestRelease,
        [DateTime]$LatestReleaseDate,
        [Uri]$ReleasesJsonUri,
        [Nullable[DateTime]]$EolDate,
        [DotNetSupportPhase]$SupportPhase
    ) {
        $this.ChannelVersion = $ChannelVersion
        $this.LatestRelease = $LatestRelease
        $this.LatestReleaseDate = $LatestReleaseDate
        $this.ReleasesJsonUri = $ReleasesJsonUri
        $this.EolDate = $EolDate
        $this.SupportPhase = $SupportPhase
    }
}

class DotNetReleaseInfo {

    [ValidateNotNullOrEmpty()][string]$ChannelVersion
    [ValidateNotNullOrEmpty()][string]$Version
    [ValidateNotNullOrEmpty()][DateTime]$ReleaseDate
    [Nullable[DateTime]]$EolDate
    [ValidateNotNull()][DotNetSupportPhase]$SupportPhase
    [DotNetRuntimeReleaseInfo]$Runtime
    [DotNetSdkReleaseInfo]$Sdk

    DotNetReleaseInfo(
        [string]$ChannelVersion,
        [string]$Version,
        [DateTime]$ReleaseDate,
        [Nullable[DateTime]]$EolDate,
        [DotNetSupportPhase]$SupportPhase,
        [DotNetRuntimeReleaseInfo]$Runtime,
        [DotNetSdkReleaseInfo]$Sdk
    ) {
        $this.ChannelVersion = $ChannelVersion
        $this.Version = $Version
        $this.ReleaseDate = $ReleaseDate
        $this.EolDate = $EolDate
        $this.SupportPhase = $SupportPhase
        $this.Runtime = $Runtime
        $this.Sdk = $Sdk
    }
}

class DotNetRuntimeReleaseInfo {

    [ValidateNotNullOrEmpty()][string]$ReleaseVersion
    [string]$Version
    [ValidateNotNull()][AllowEmptyCollection()][DotNetFileInfo[]]$Files

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
    [ValidateNotNull()][AllowEmptyCollection()][DotNetFileInfo[]]$Files

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

    [ValidateNotNullOrEmpty()][ValidateSet("Runtime", "Sdk")][string]$PackageType
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