# 1.0.7961.32481

## taken from: https://raw.githubusercontent.com/brettmillerb/Toolbox/master/Public/Get-CommandInfo.ps1

function Get-CommandInfo {
    <#
    .SYNOPSIS
        Get-Command helper.
    .DESCRIPTION
        Get-Command helper.
    #>

    [CmdletBinding()]
    param (
        # The name of a command.
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [String]$Name,

        # A CommandInfo object.
        [Parameter(Mandatory, ParameterSetName = 'FromCommandInfo')]
        [System.Management.Automation.CommandInfo]$CommandInfo,

        # If a module name is specified the private / internal scope of the module will be searched.
        [String]$ModuleName,

        # Claims and discards any other supplied arguments.
        [Parameter(ValueFromRemainingArguments, DontShow)]
        $EaterOfArgs
    )

    if ($Name) {
        if ($ModuleName) {
            try {
                if (-not ($moduleInfo = Get-Module $ModuleName)) {
                    $moduleInfo = Import-Module $ModuleName -Global -PassThru
                }
                $CommandInfo = & $moduleInfo ([ScriptBlock]::Create('Get-Command {0}' -f $Name))
            }
            catch {
                $pscmdlet.ThrowTerminatingError($_)
            }
        }
        else {
            $CommandInfo = Get-Command -Name $Name
        }
    }

    if ($CommandInfo -is [System.Management.Automation.AliasInfo]) {
        $CommandInfo = $CommandInfo.ResolvedCommand
    }

    return $CommandInfo
}

## taken from: https://raw.githubusercontent.com/brettmillerb/Toolbox/master/Public/Get-Syntax.ps1

Function Get-Syntax {
    <#
    .SYNOPSIS
        Get the syntax for a command.
    .DESCRIPTION
        Get the syntax for a command. A wrapper for Get-Command -Syntax.
    #>

    [CmdletBinding()]
    [Alias('synt', 'syntax')]
    param (
        # The name of a command.
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName, ParameterSetName = 'ByName')]
        [String]$Name,

        # A CommandInfo object.
        [Parameter(Mandatory, ValueFromPipeline, ParameterSetName = 'FromCommandInfo')]
        [System.Management.Automation.CommandInfo]$CommandInfo,

        # Write syntax in the short format used by Get-Command.
        [Switch]$Short
    )

    begin {
        $commonParams = @(
            [System.Management.Automation.Internal.CommonParameters].GetProperties().Name
            [System.Management.Automation.Internal.ShouldProcessParameters].GetProperties().Name
            [System.Management.Automation.Internal.TransactionParameters].GetProperties().Name
        )
    }

    process {
        $CommandInfo = Get-CommandInfo @psboundparameters
        foreach ($parameterSet in $CommandInfo.ParameterSets) {
            if ($Short) {
                "`n{0} {1}" -f $CommandInfo.Name, $parameterSet
            }
            else {
                $stringBuilder = [System.Text.StringBuilder]::new().AppendFormat('{0} ', $commandInfo.Name)

                $null = foreach ($parameter in $parameterSet.Parameters) {
                    if ($parameter.Name -notin $commonParams) {
                        if (-not $parameter.IsMandatory) {
                            $stringBuilder.Append('[')
                        }

                        if ($parameter.Position -gt [Int32]::MinValue) {
                            $stringBuilder.Append('[')
                        }

                        $stringBuilder.AppendFormat('-{0}', $parameter.Name)

                        if ($parameter.Position -gt [Int32]::MinValue) {
                            $stringBuilder.Append(']')
                        }

                        if ($parameter.ParameterType -ne [Switch]) {
                            $stringBuilder.AppendFormat(' <{0}>', $parameter.ParameterType.Name)
                        }

                        if (-not $parameter.IsMandatory) {
                            $stringBuilder.Append(']')
                        }

                        $stringBuilder.AppendLine().Append(' ' * ($commandInfo.Name.Length + 1))
                    }
                }

                $stringBuilder.AppendLine().ToString()
            }
        }
    }
}
Get-Item -Path function:\help -EA SilentlyContinue | Remove-Item
Set-Alias -Name help -Value Get-Syntax

Function Search-Item {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias("pattern")]
        [string]$filter = "*.*",

        [Parameter(Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [Alias("PSPath")]
        [string]$path = $PWD

    )

    PROCESS {

        Write-Host "Searching in $path"

        Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | ForEach-Object {
            Write-Output $_.FullName
        }
    }
}
Set-Alias -Name search -Value Search-Item

Function Show-Calendar {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0)]
        [int]
        $Month = (Get-Date).Month,

        [Parameter(Position = 1)]
        [int]
        $Year = (Get-Date).Year,

        [Parameter()]
        [switch]
        $AsObject
    )

    $fgB = "`e[30m"
    $bgW = "`e[47m"
    $N = "`e[0m"

    $beginningOfMonth = Get-Date -Year $Year -Month $Month -Day 1
    $monthName = $beginningOfMonth.ToString("MMMM")
    $yearString = $beginningOfMonth.ToString("yyyy")
    $currentMonth = $beginningOfMonth.Month
    $currentDay = $beginningOfMonth
    $monthObject = while ($currentDay.Month -eq $currentMonth) {
        $currentDay
        try {
            $currentDay = Get-Date -Year $Year -Month $Month -Day ($currentDay.Day + 1)
        }
        catch {
            break
        }
    }

    if ($AsObject) {
        return $monthObject
    }

    $title = "$monthName $yearString"
    $sp = [Math]::Floor((21 - $monthName.Length - 5) / 2)

    $title.PadLeft((21 - $sp), ' ')
    "Su Mo Tu We Th Fr Sa"
    $line = ''
    foreach ($day in $monthObject) {
        $dayValue = $day.DayOfWeek.value__

        if ($day.Day -eq 1) {
            $line += ' ' * ($dayValue * 3)
        }

        if ($day.Date -eq (Get-Date).Date) {
            $line += $fgB + $bgW
        }

        $line += $day.Day.ToString().PadLeft(2)

        if ($day.Date -eq (Get-Date).Date) {
            $line += $N
        }

        if ($dayValue -eq 6) {
            $line += [Environment]::NewLine
        }
        else {
            $line += ' '
        }
    }

    if ($line[-1..-2] -notcontains "`n") {
        $line += [Environment]::NewLine
    }

    $line
}
Set-Alias -Name cal -Value Show-Calendar -Force

Function Upgrade-PowerShell {
    $has = (Get-Process -Name "pwsh" -EA SilentlyContinue | Select-Object -First 1)
    if (-not $has) {
        Remove-Item -Path "$Env:LOCALAPPDATA\Microsoft\powershell-daily" -Recurse -Force -EA SilentlyContinue
        Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -daily"
    }
    else {
        Write-Host "pwsh.exe is already running. Please, call all PowerShell Core sessions, including Visual Studio Code integrated terminal sessions." -ForegroundColor Yellow
    }
}
Set-Alias -Name update -Value Upgrade-PowerShell
