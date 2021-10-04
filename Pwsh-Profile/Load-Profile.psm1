Function Load-Profile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $name,
        [switch] $quiet,

        [Parameter(Mandatory = $false, ValueFromRemainingArguments)]
        $remainingArgs
    )

    BEGIN {

        Function Get-PwshExpression {
            param([string]$path)

            ## Using [IO.File]::ReadAllText() instead of Get-Content -Raw for performance purposes

            $content = [IO.File]::ReadAllText($path)
            $content = $content -replace "(?<!\-)[Ff]unction\ +([A-Za-z]+)", 'Function global:$1'
            $content = $content -replace "[Ss][Ee][Tt]\-[Aa][Ll][Ii][Aa][Ss]\ +(.*)", 'Set-Alias -Scope Global $1'

            Write-Output $content
        }

        Function Get-CachedPowerShellProfile {
            [CmdletBinding()]
            param( [string]$name, [switch]$quiet )

            ## Using [IO.File]::Exists() and [IO.Directory]::Exists() instead of Test-Path for performance purposes
            ## Using [IO.File]::GetLastWriteTime() instead of (Get-Item -Path).LastWriteTimeUtc for performance purposes
            ## Using [IO.Path]::Combine() instead of Join-Path for performance purposes

            BEGIN {

                Function New-CachedPowerShellProfile {
                    param( [string]$friendlyName, [string]$content )
                    $cachedProfilePath = Get-CachedProfilePath -Name $name
                    Write-Verbose "Creating cached PowerShell profile '$friendlyName'"
                    Write-Verbose "$cachedProfilePath"
                    Set-Content -Path $cachedProfilePath -Value (Get-PwshExpression -Path $content)
                    Write-Output $cachedProfilePath
                }

                $friendlyName = $name
                if (-not $name) { $friendlyName = "profile" }
            }

            PROCESS {
                $originalProfile = Get-Profile -Name $name
                if (-not $originalProfile -or (-not ([IO.File]::Exists($originalProfile)))) {
                    if (-not $quiet.IsPresent) {
                        Write-Host "No such profile '$friendlyName'." -ForegroundColor Magenta
                    }
                    return
                }

                if ($name -eq "profiles") {
                    return (Get-ProfilePath -Name $name)
                }

                $cachedProfile = Get-CachedProfile -Name $name
                
                if ($cachedProfile -and ([IO.File]::Exists($cachedProfile))) {
                    Write-Verbose "Cached PowerShell profile '$friendlyName' exists."
                    $originalProfileTimestamp = [IO.File]::GetLastWriteTime($originalProfile)
                    $cachedProfileTimestamp = [IO.File]::GetLastWriteTime($cachedProfile)
                    if ($originalProfileTimeStamp -gt $cachedProfileTimestamp) {
                        Write-Verbose "Cached PowerShell profile is obsolete. Replacing..."
                        $cachedProfile = New-CachedPowerShellProfile -FriendlyName $friendlyName -Content $originalProfile
                    }
                }
                else {
                    Write-Verbose "Cached PowerShell profile '$friendlyName' does not exist."
                    $cachedProfile = New-CachedPowerShellProfile -FriendlyName $friendlyName -Content $originalProfile
                }

                Write-Output $cachedProfile
            }
        }
    }

    PROCESS {

        $powerShellProfile = Get-CachedPowerShellProfile -Name $name -Quiet:$quiet

        if ($powerShellProfile -and ([IO.File]::Exists($powerShellProfile))) {
            if (-not $quiet.IsPresent) {
                Write-Host "Loading $name profile." -ForegroundColor Gray
            }
            $expression = ". `"$powerShellProfile`" $remainingArgs"
            Invoke-Expression -Command $expression
        }

        CheckFor-ProfileUpdate -Name $name | Out-Null
    }
}

Set-Alias -Name lp -Value Load-Profile
