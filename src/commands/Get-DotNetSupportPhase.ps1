<#
.SYNOPSIS
    Convert the string-representation of a support-phase to a DotNetSupportPhase enum value
.PARAMETER SupportPhase
    The string-representation of a support-phase name to the corresponding DotNetSupportPhase enum value
#>
function Get-DotNetSupportPhase {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]        
        [string]
        $SupportPhase
    )

    if(-not $SupportPhase) {
        foreach($value in [DotNetSupportPhase].GetEnumValues()) {
            Write-Output $value
        }        
        return
    }

    switch ($supportPhase) {
        "preview" {
            return [DotNetSupportPhase]::Preview
        }        
        "go-live" {
            return [DotNetSupportPhase]::GoLive
        }
        "active" {
            return [DotNetSupportPhase]::Active
        }
        "maintenance" {
            return [DotNetSupportPhase]::Maintenance
        }
        "eol" {
            return [DotNetSupportPhase]::EOL
        }
        Default {
            throw "Cannot parse value '$supportPhase' as DotNetSupportPhase"
        }
    }
}