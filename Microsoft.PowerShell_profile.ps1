# 1.0.7896.18146

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

        $separator = [IO.Path]::PathSeparator
        $joinedPaths = [string]::Join($separator, $paths)

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
    [CmdletBinding(DefaultParameterSetName = "Path")]
    param(
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "Path")]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "Remote")]
        [string] $name = $null,
    
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Path")]
        [string] $folder = (Split-Path $profile -Parent),
    
        [Parameter(ParameterSetName = "Remote")]
        [switch] $remote
    )
    
    BEGIN {
    
        Function Test-WebPath {
            param( [string]$uri )
    
            try { irm -Method HEAD -Uri $uri | Out-Null } catch { return $false }
            return $true
        }
    
        $pattern = (Split-Path $profile -Leaf)
    
        $template = "Microsoft.PowerShell_%{NAME}%profile.ps1"
        $address = "https://raw.githubusercontent.com/springcomp/powershell_profile.ps1/master/"
    }
    
    PROCESS {
    
        if (-not $name) { $name = "profile" }
    
        if ($remote.IsPresent) {
    
            $alternate = $pattern.Replace("profile", "$name-profile")
            $profilePath = "$($address)$($alternate)"
            if (-not (Test-WebPath -Uri $profilePath)) {
                $alternate = $pattern.Replace("profile", "$name")
                $profilePath = "$($address)$($alternate)"
                if (-not (Test-WebPath -Uri $profilePath)) { return }
            }
        }
    
        else {
    
            ## Using [IO.File]::Exists() instead of Test-Path for performance purposes
            ## Using [IO.Path]::Combine() instead of Join-Path for performance purposes
    
            $alternate = $pattern.Replace("profile", $name)
            $profilePath = [IO.Path]::Combine($folder, $alternate)
            if (-not ([IO.File]::Exists($profilePath))) {
                $alternate = $pattern.Replace("profile", "$name-profile")
                $profilePath = [IO.Path]::Combine($folder, $alternate)
                if (-not ([IO.File]::Exists($profilePath))) { return }
            }
        }
    
        Write-Output $profilePath
    }
}             
Function Get-VersionProfile {
    [CmdletBinding()]
    param( [string]$name, [switch]$remote )

    if ($remote.IsPresent) {
    
        $address = Get-Profile -Name $name -Remote
        if (-not $address) { return "0.0.0000.00000" }
    
        $line = (irm -Method Get -Uri $address).Split("`n") |`
            Select-Object -First 1
    }
    else {
    
        $cachedProfilesFolder = [IO.Path]::Combine($Env:TEMP, "PowerShell_profiles")
        $cachedProfile = Get-Profile -Name $name -Folder $cachedProfilesFolder
        if (-not ([IO.File]::Exists($cachedProfile))) { return "0.0.0000.00000" }
    
        $line = Get-Content -Path $cachedProfile |`
            Select-Object -First 1
    }

    $pattern = "^#\s*(?<ver>\d+\.\d+(?:\.\d{4}){2}\d)\s*`$"
    $matches = ($line -match $pattern)
    if (-not ($line -match $pattern)) {
        return "0.0.0000.00000"
    }

    return $matches["ver"]
}

Function CheckFor-UpdateProfile {
    [CmdletBinding()]
    param( [string]$name = "" )

    BEGIN {

        Function Get-LastUpdated {
            [CmdletBinding()]
            param( [string]$name )

            $cachedProfilesFolder = [IO.Path]::Combine($Env:TEMP, "PowerShell_profiles")
            $cachedProfileUpdateFile = [IO.Path]::Combine($cachedProfilesFolder, "$($name)_update.txt")
            if (-not ([IO.File]::Exists($cachedProfileUpdateFile))) {
                return [DateTime]::MinValue
            }

            $line = Get-Content -Path $cachedProfileUpdateFile |`
                Select-Object -First 1

            $pattern = "\s*(?<ts>\d{4}(?:\-\d{2}){2}T\d{2}(?::\d{2}){2}\.\d{7}Z)\s*`$"
            if (-not ($line -match $pattern)) {
                return [DateTime]::MinValue
            }

            $timestamp = [DateTime]::Parse($matches["ts"])
            return $timestamp
        }
        Function Needs-Update {
            [CmdletBinding()]
            param( [string]$name )

            $CHECK_FOR_UPDATES_FREQUENCY_IN_DAYS = 1

            $lastUpdated = Get-LastUpdated -Name $name
            $now = (Get-Date).ToUniversalTime()
            if (($now - $lastUpdated).TotalDays -gt $CHECK_FOR_UPDATES_FREQUENCY_IN_DAYS) {
                $version = Get-VersionProfile -Name $name
                $remoteVer = Get-VersionProfile -Name $name -Remote
                return ($remoteVer -gt $version)
            }

            return $false
        }
    }

    PROCESS {
        if (Needs-Update -Name $name) {
            Write-Host "Profile '$name' has new version. Type 'update-profile $name -reload' to update." -ForegroundColor Yellow
        }
    }
}

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
                    if (-not $quiet.IsPresent) {
                        Write-Host "No such profile '$name'." -ForegroundColor Magenta
                    }
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

        CheckFor-UpdateProfile -Name $name

        $powerShellProfile = Get-CachedPowerShellProfile -Name $name -Quiet:$quiet

        if ($powerShellProfile -and ([IO.File]::Exists($powerShellProfile))) {
            if (-not $quiet.IsPresent) {
                Write-Host "Loading $name profile." -ForegroundColor Gray
            }
            $expression = ". `"$powerShellProfile`" $remainingArgs"
            Invoke-Expression -Command $expression
        }
    }
}

Set-Alias -Name lp -Value Load-Profile

Function Download-Profile {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$name = "",
        [switch]$force,
        [switch]$load
    )

    BEGIN {

        $uri = Get-Profile -Name $name -Remote
        $destination = Get-Profile -Name $name

        Write-Host $uri
        Write-Host $destination

    }
    PROCESS {

        if (-not (Test-Path $destination) -or $force.IsPresent) {
            Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
                -Headers @{"Cache-Control"="no-cache"} `
                -OutFile $destination
            
            Write-Host "$destination updated." -ForegroundColor Cyan

            if ($load.IsPresent) {
                Load-Profile $name
            }
        }
        else {
            Write-Host "$destination exists. Please, use -force to overwrite." -ForegroundColor Red
        }
    }
}

Function Update-Profile {
    param ( [string]$name = "", [switch]$reload )
    Download-Profile -Name $name -Force -Load:$reload
    Set-LastUpdatedProfile -Name $name
}

$hasAlias = [bool] (Get-Alias -Name lp |? { $_.ResolvedCommand.Name -eq "Out-Printer"  })
if ($hasAlias) { Remove-Item -Path "alias:\lp" }
Set-Alias -Name up -Value Update-Profile

Function Install-Profile {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$name,
        [switch]$load
    )

    BEGIN{

        $profiles = Split-Path $profile -Leaf
        $profiles = $profiles.Replace("profile", "profiles-profile")
        $profiles = Join-Path (Split-Path $profile) -ChildPath $profiles

        if (-not (Test-Path $profiles)) { New-Item -Path $profiles -ItemType File | Out-Null }

        Function Get-NextState {
            param(
                [string] $line,
                [int] $state
            )
            $nextState = $state
            if (($state -eq 0) -and ($line -match "## Load useful profiles")) { $nextState = 1 }
            if (($state -eq 1) -and ($line -match "## SECURITY - SENSITIVE DATA")) { $nextState = 2 }
            Write-Output $nextState
        }

        Function Get-LoadedProfiles {
            $before = @()
            $content = @()
            $after = @()
            $state = 0

            Get-Content -Path $profiles |? {

                $line = $_
                $nextState = Get-NextState -Line $line -State $state

                switch ($state) {
                    0 {
                        $before += $line
                    }
                    1 {
                        if ($nextState -eq 2) { $after += $line }
                        else { $content += $line }
                    }
                    2 {
                        $after += $line
                    }
                }

                $state = $nextState
            }

            Write-Output $before, $content, $after
        }
    }
    PROCESS{

        if ($name -eq "profiles"){
            Write-Host "Cannot install `"profiles`" profile into itself." -ForegroundColor Red
            return 
        }

        $newLine = "Load-Profile `"$($name.ToLowerInvariant())`""

        if (Get-Content -Path $profiles |? { $_ -match $newLine }){
            Write-Host "Profile $name already registered to the profiles profile." -ForegroundColor Yellow
        } else {
            Update-Profile -Name $name -Reload:$load

            $lines = Get-LoadedProfiles 
            $lines[1] += $newLine
            $lines[1] = $lines[1] | Sort-Object

            Clear-Content -Path $profiles 
            $lines |% { $_ |% { Add-Content -Path $profiles -Value $_ }}
        }
    }
}

Function Set-LastUpdatedProfile {
    [CmdletBinding()]
    param( [string]$name = "", [DateTime]$dateTime = [DateTime]::UtcNow )
    
    $cachedProfilesFolder = [IO.Path]::Combine($Env:TEMP, "PowerShell_profiles")
    $cachedProfileUpdateFile = [IO.Path]::Combine($cachedProfilesFolder, "$($name)_update.txt")
    
    $timestamp = $dateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
    
    Set-Content `
        -Path $cachedProfileUpdateFile `
        -Value $timestamp
}

## 

Load-Profile "profiles" -Quiet
