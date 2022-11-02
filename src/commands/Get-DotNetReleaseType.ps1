<#
.SYNOPSIS
    Converts the string-representation of a release type to a DotNetReleaseType enum value
.PARAMETER SupportPhase
    The string-representation of a release-type name
#>
function Get-DotNetReleaseType {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]        
        [string]
        $ReleaseType
    )

    if(-not $ReleaseType) {
        foreach($value in [DotNetReleaseType].GetEnumValues()) {
            Write-Output $value
        }        
        return
    }

    switch ($ReleaseType) {
        "sts" {
            return [DotNetReleaseType]::STS
        }        
        "lts" {
            return [DotNetReleaseType]::LTS
        }       
        Default {
            throw "Cannot parse value '$ReleaseType' as DotNetReleaseType"
        }
    }
}