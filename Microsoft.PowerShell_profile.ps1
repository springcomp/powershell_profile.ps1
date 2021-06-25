## $Env:PATH management
Function Add-DirectoryToPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [string] $path,
        [string] $variable = "PATH",

        [switch] $clear,
        [switch] $force,
        [switch] $prepend,
        [switch] $whatIf
    )

    BEGIN {

        ## normalize paths

        $count = 0

        $paths = @()

        if (-not $clear.IsPresent) {

            $environ = Invoke-Expression "`$Env:$variable"
            $environ.Split(";") | ForEach-Object {
                if ($_.Length -gt 0) {
                    $count = $count + 1
                    $paths += $_.ToLowerInvariant()
                }
            }

            Write-Verbose "Currently $($count) entries in `$env:$variable"
        }

        Function Array-Contains {
            param(
                [string[]] $array,
                [string] $item
            )

            $any = $array | Where-Object -FilterScript {
                $_ -eq $item
            }

            Write-Output ($null -ne $any)
        }
    }

    PROCESS {

        ## Using [IO.Directory]::Exists() instead of Test-Path for performance purposes

        ##$path = $path -replace "^(.*);+$", "`$1"
        ##$path = $path -replace "^(.*)\\$", "`$1"
        if ([IO.Directory]::Exists($path) -or $force.IsPresent) {

            #$path = (Resolve-Path -Path $path).Path
            $path = $path.Trim()

            $newPath = $path.ToLowerInvariant()
            if (-not (Array-Contains -Array $paths -Item $newPath)) {
                if ($whatIf.IsPresent) {
                    Write-Host $path
                }

                if ($prepend.IsPresent) { $paths = , $path + $paths }
                else { $paths += $path }

                Write-Verbose "Adding $($path) to `$env:$variable"
            }
        }
        else {

            Write-Host "Invalid entry in `$Env:$($variable): ``$path``" -ForegroundColor Yellow

        }
    }

    END {

        ## re-create PATH environment variable

        $joinedPaths = [string]::Join(";", $paths)

        if ($whatIf.IsPresent) {
            Write-Output $joinedPaths
        }
        else {
            Invoke-Expression " `$env:$variable = `"$joinedPaths`" "
        }
    }

}

## Well-known profiles script
Function Get-DefaultProfile {
    $___profile = Join-Path -Path (Split-Path -Path $profile -Parent) -ChildPath "profile.ps1"
    Write-Output $___profile
}
Function Remove-DefaultProfile {
    $___profile = Get-DefaultProfile
    if (Test-Path $___profile) { 
        Write-Host "Removing default profile file." -ForegroundColor Yellow
        Remove-Item $___profile -Force
    }
}

Function Get-Profile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [string] $name = $null,

        [Parameter(Mandatory = $false, Position = 1)]
        [string] $folder = (Split-Path $profile -Parent)
    )

    BEGIN {

        $pattern = (Split-Path $profile -Leaf)
    }

    PROCESS {

        ## Using [IO.File]::Exists() instead of Test-Path for performance purposes
        ## Using [IO.Path]::Combine() instead of Join-Path for performance purposes

        if (-not $name) { $name = "profile" }
        $alternate = $pattern.Replace("profile", $name)
        $profilePath = [IO.Path]::Combine($folder, $alternate)
        if (-not ([IO.File]::Exists($profilePath))) {
            $alternate = $pattern.Replace("profile", "$name-profile")
            $profilePath = [IO.Path]::Combine($folder, $alternate)
            if (-not ([IO.File]::Exists($profilePath))) { return }
        }
        Write-Output $profilePath
    }
}
Function Load-Profile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string] $name,

        [Parameter(Mandatory = $false, Position = 1, ValueFromRemainingArguments)]
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
            param([string]$name)

            ## Using [IO.File]::Exists() and [IO.Directory]::Exists() instead of Test-Path for performance purposes
            ## Using [IO.File]::GetLastWriteTime() instead of (Get-Item -Path).LastWriteTimeUtc for performance purposes
            ## Using [IO.Path]::Combine() instead of Join-Path for performance purposes

            BEGIN {
                $cachedProfilesFolder = [IO.Path]::Combine($Env:TEMP, "PowerShell_profiles")
                if (-not ([IO.Directory]::Exists($cachedProfilesFolder))) {
                    New-Item -Path $cachedProfilesFolder -ItemType Directory | Out-Null
                }

                $pattern = (Split-Path $profile -Leaf)
                $cachedProfileName = $pattern.Replace("profile", "$name-profile")

                Function New-CachedPowerShellProfile {
                    Write-Verbose "Creating cached PowerShell profile '$name'"
                    $newProfile = [IO.Path]::Combine($cachedProfilesFolder, $cachedProfileName)
                    Set-Content -Path $newProfile -Value (Get-PwshExpression -Path $originalProfile)
                    Write-Output $newProfile
                }
            }

            PROCESS {
                $originalProfile = Get-Profile -Name $name
                if (-not $originalProfile -or (-not ([IO.File]::Exists($originalProfile)))) {
                    Write-Host "No such profile '$name'." -ForegroundColor Magenta
                    return
                }
                $cachedProfile = Get-Profile -Name $name -Folder $cachedProfilesFolder
                
                if ($cachedProfile -and ([IO.File]::Exists($cachedProfile))) {
                    Write-Verbose "Cached PowerShell profile '$name' exists."
                    $originalProfileTimestamp = [IO.File]::GetLastWriteTime($originalProfile)
                    $cachedProfileTimestamp = [IO.File]::GetLastWriteTime($cachedProfile)
                    if ($originalProfileTimeStamp -gt $cachedProfileTimestamp) {
                        Write-Verbose "Cached PowerShell profile is obsolete. Replacing..."
                        $cachedProfile = New-CachedPowerShellProfile
                    }
                }
                else {
                    Write-Verbose "Cached PowerShell profile '$name' does not exist."
                    $cachedProfile = New-CachedPowerShellProfile
                }

                Write-Output $cachedProfile
            }
        }
    }

    PROCESS {

        $powerShellProfile = Get-CachedPowerShellProfile -Name $name

        if ($powerShellProfile -and ([IO.File]::Exists($powerShellProfile))) {
            Write-Host "Loading $name profile." -ForegroundColor Gray
            $expression = ". `"$powerShellProfile`" $remainingArgs"
            Invoke-Expression -Command $expression
        }
    }
}

Set-Alias -Name lp -Value Load-Profile

## PowerShell Modules

$_module_paths = `
    "$Env:LOCALAPPDATA\Microsoft\Powershell-modules", `
    "$Env:LOCALAPPDATA\Microsoft\PowerShell-daily\Modules", `
    "C:\Program Files\PowerShell\Modules", `
    "C:\Program Files\WindowsPowerShell\Modules", `
    "C:\Windows\system32\WindowsPowerShell\v1.0\Modules"

$_module_paths | Add-DirectoryToPath -Clear -Force -Variable "PSModulePath"

## Load useful profiles

##Load-Profile "azure"
Load-Profile "b64"
Load-Profile "dotnet"
Load-Profile "docker"
Load-Profile "git"
Load-Profile "json"
Load-Profile "local"
Load-Profile "oh-my-posh"
Load-Profile "psreadline"
Load-Profile "utils"
Load-Profile "vim"

## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "C:\Projects\springcomp\clip\src\clip\bin\Release"

$_paths | Add-DirectoryToPath 

## SECURITY - SENSITIVE DATA

#Load-Profile "secret"

## SENSITIVE DATA

## USEFUL FUNCTIONS
