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

Load-Profile "base"

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
Load-Profile "vim"

## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "D:\Projects\springcomp\clip\src\clip\bin\Debug"

$_paths | Add-DirectoryToPath 

## SECURITY - SENSITIVE DATA

#Load-Profile "secret"

## SENSITIVE DATA

## USEFUL FUNCTIONS

Function c {
    param([string] $path = ".")
    . code $path
}
Function ccv { Get-CurrentVersion | clipp }
Function cguid { [Guid]::NewGuid().guid | clipp }
Function cwd { $PWD.Path | clipp }
Function csp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$path = $profile
    )
    code (split-path -path "$path")
}
Function esp { explorer (split-path $args) }
Function ewd {
    param([string] $path = $PWD.Path)
    if ($path.EndsWith("\")) {
        $path = $path.Substring(0, $path.Length - 1)
    }
    explorer $path 
}
Set-Alias -Name e -Value ewd
Function filezilla { & 'C:\Portable Apps\FileZilla\FileZillaPortable.exe' }
Set-Alias -Name zilla -Value filezilla
Function Get-CurrentVersion {
    $epoch = [DateTime]::Parse("2000-01-01")
    $now = Get-Date
    $build = [Math]::Floor(($now - $epoch).TotalDays)
    $rev = [Math]::Floor(($now - $now.Date).TotalSeconds / 2)
    Write-Output "1.0.$($build).$($rev)"
}
Set-Alias -Name gcv -Value Get-CurrentVersion
Function izarc { & 'C:\Portable Apps\IZarc2Go\IZArc2Go.exe' }
Function keepass { & 'C:\Portable Apps\KeePass\KeePass.exe' }
Set-Alias -Name kp -Value keepass

Function rmf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [Alias("FullName")]
        [string]$path
    )
    Remove-Item `
        -Path $path `
        -Recurse `
        -Force 
}
Function servicebus { & 'C:\Portable Apps\ServiceBus Explorer\ServiceBusExplorer.exe' }
Set-Alias -Name sbex -Value servicebus

Function Upgrade-PowerShell {
    Remove-Item -Path "$Env:LOCALAPPDATA\Microsoft\powershell-daily" -Recurse -Force -EA SilentlyContinue
    Copy-Item -Path "$Env:LOCALAPPDATA\Microsoft\powershell-daily.old\assets" -Destination "$Env:LOCALAPPDATA\Microsoft\powershell-daily\assets" -Recurse
    Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -daily"
}
Set-Alias -Name update -Value Upgrade-PowerShell