$moduleName = "DotNetReleasesPowershell"
$modulePath = Join-Path $PSScriptRoot "../src/$moduleName.psm1"
$outputDir = Join-Path $PSScriptRoot "../docs/commands/"

$PSDefaultParameterValues = @{ '*:Encoding' = 'utf8' }

$commonParameters = @(    
    "Debug",
    "ErrorAction",
    "ErrorVariable",
    "InformationAction",
    "InformationVariable",
    "OutVariable",
    "OutBuffer",
    "PipelineVariable",
    "Verbose",
    "WarningAction",
    "WarningVariable"
)

#
# Create ouput directory
#
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir > $null
}

#
# (Re)load module
#
if (Get-Module $moduleName) {
    Remove-Module $moduleName
}
Import-Module $modulePath


function generateIndex {

    param(
        [Parameter(Mandatory = $true)][System.Management.Automation.FunctionInfo[]]$commands
    )

    $outputPath = Join-Path $outputDir "README.asc"
    
    "// This file is auto-generated by $($MyInvocation.MyCommand.Name)" > $outputPath
    "// Do not edit this file manually as changes will be overwritten the next time the script runs" >> $outputPath
    "" >> $outputPath
    "= $ModuleName Commands" >> $outputPath
    "" >> $outputPath

    foreach ($command in $commands) {

        "* link:$($command.Name).asc[$($command.Name)]" >> $outputPath
        "" >> $outputPath 
    }
}



function generateCommandPage {

    param(
        [Parameter(Mandatory = $true)][System.Management.Automation.FunctionInfo]$command
    )

    $help = Get-Help -Name $command.Name

    function Get-ParameterHelp($parameterName) {
        foreach ($parameterHelp in $help.parameters.parameter) {
            if ($parameterHelp.name -eq $parameterName) {
                return $parameterHelp
            }
        }
    }


    $outputPath = Join-Path $outputDir "$($command.Name).asc"
    "// This file is auto-generated by $($MyInvocation.MyCommand.Name)" > $outputPath
    "// Do not edit this file manually as changes will be overwritten the next time the script runs" >> $outputPath
    "= $($command.Name) Command" >> $outputPath
    "" >> $outputPath


    if ($help.Synopsis) {
        $help.Synopsis >> $outputPath
        "" >> $outputPath
    }
    $description = ($help.Description | Out-String).Trim()
    if ($description) {
        "== Description" >> $outputPath
        "" >> $outputPath
        $description >> $outputPath
        "" >> $outputPath
    }

    if ($help.examples.example) {
        
        $exampleNumber = 1

        "== Examples" >> $outputPath
        "" >> $outputPath
        foreach ($example in $help.examples.example) {
            
            $title = $example.title.Trim('-').Trim()
            if (-not $title) {
                $title = "Example $exampleNumber"
            }
            "=== $title" >> $outputPath
            "" >> $outputPath

            $description = ($example.remarks | Out-String).Trim()
            if ($description) {
                $description >> $outputPath
                "" >> $outputPath
            }

            "[source,powershell]" >> $outputPath
            "----" >> $outputPath
            $example.code >> $outputPath
            "----" >> $outputPath
            "" >> $outputPath


            $exampleNumber += 1 
        }

    }


    $parameterSetCount = ($command.ParameterSets | Measure-Object).Count
    $parameterCount = ($command.Parameters | Measure-Object).Count
    
    if ($parameterCount -gt 0) {
        "== Parameters" >> $outputPath
        "" >> $outputPath
        
        if ($parameterSetCount -gt 1) {
            
            foreach ($parameterSet in $command.ParameterSets) {
                "=== Parameter Set ``$($parameterSet.Name)``" >> $outputPath
                "" >> $outputPath
                foreach ($parameter in $parameterSet.Parameters) {
                    if ($commonParameters -contains $parameter.Name) {
                        continue
                    }
                    "==== Parameter ``$($parameter.Name)``" >> $outputPath
                    "" >> $outputPath
                    $parameterHelp = Get-ParameterHelp $parameter.Name
                    if ($parameterHelp.description) {
                        $parameterDescription = ($parameterHelp.description | Out-String).Trim()
                        $parameterDescription >> $outputPath
                        "" >> $outputPath
                    }
                }
            }
        }
        else {
            foreach ($parameter in $command.Parameters.Values) {
                if ($commonParameters -contains $parameter.Name) {
                    continue
                }
                "=== Parameter ``$($parameter.Name)``" >> $outputPath
                "" >> $outputPath

                $parameterHelp = Get-ParameterHelp $parameter.Name
                if ($parameterHelp.description) {
                    $parameterDescription = ($parameterHelp.description | Out-String).Trim()
                    $parameterDescription >> $outputPath
                    "" >> $outputPath
                }
            }
        }
    }


   
}


$commands = Get-Command -Module $moduleName
generateIndex $commands
foreach ($command in $commands) {
    generateCommandPage $command
}


