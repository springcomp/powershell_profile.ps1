# 1.0.7931.32014

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
Function CheckFor-ProfileUpdate {
    [CmdletBinding()]
    param( [string]$name = "" )

    BEGIN {

        Function Get-LastUpdated {
            [CmdletBinding()]
            param( [string]$name )

            Write-Verbose "Checking whether cached profile update file for $name exists."

            $cachedProfileUpdateFile = Get-CachedProfileUpdatePath -Name $name
            if (-not ([IO.File]::Exists($cachedProfileUpdateFile))) {
                Write-Verbose "Cached profile update file does not exist."
                return [DateTime]::MinValue
            }

            $line = Get-Content -Path $cachedProfileUpdateFile |`
                Select-Object -First 1

            $pattern = "\s*(?<ts>\d{4}(?:\-\d{2}){2}T\d{2}(?::\d{2}){2}\.\d{7}Z)\s*`$"
            if (-not ($line -match $pattern)) {
                Write-Verbose "Cached profile update file does not contain a date/time pattern."
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

            Write-Verbose "$($name): Last updated: $lastUpdated; Now: $now."
            Write-Verbose "$($name): Last updated: $(($now - $lastUpdated).TotalDays) days ago."

            if (($now - $lastUpdated).TotalDays -gt $CHECK_FOR_UPDATES_FREQUENCY_IN_DAYS) {
                $version = Get-ProfileVersion -Name $name
                $remoteVer = Get-ProfileVersion -Name $name -Remote
                Write-Verbose "Checking timestamp for profile $name."
                Write-Verbose "Local version: $version; Remote version: $remoteVer"
                $needsUpdate = ($remoteVer -gt $version)
                if (-not $needsUpdate){
                    Write-Verbose "Updating last update check timestamp for profile $name."
                    Set-LastUpdatedProfile -Name $name
                }
                return $needsUpdate
            } else {
                Write-Verbose "Skipped checking for updates for profile $name."
            }

            return $false
        }
    }

    PROCESS {
        if (($name -ne "profiles") -and (Needs-Update -Name $name)) {
            $_n = "Profile '$name' "; $_a = "$name "
            if (-not $name) { $_n = "Main profile "; $_a = "" }
            Write-Host "$($_n)has new version. Type 'update-profile $($_a)-reload' to update." -ForegroundColor Yellow
        }
    }
}
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

        ## attempt to replace existing profile

        $destination = Get-Profile -Name $name

        ## otherwise, dowload a new profile

        if (-not $destination) {
            $destination = Get-ProfilePath -Name $name
            if ($name -eq "") {
                $destination = Get-ProfilePath -Name $name -Alternate
            }
        }

        Write-Host $uri
        Write-Host $destination

    }
    PROCESS {

        if (-not (Test-Path $destination) -or $force.IsPresent) {
            Invoke-RestMethod `
                -Method Get `
                -Uri $uri `
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
Function Get-CachedPowerShellProfileFolder {
    $tempFolder = $Env:TEMP; if ($PSVersionTable.Platform -ne "Win32NT") { $tempFolder = "/tmp" }
    $cachedProfilesFolder = [IO.Path]::Combine($tempFolder, "PowerShell_profiles")
    if (-not ([IO.Directory]::Exists($cachedProfilesFolder))) {
        New-Item -Path $cachedProfilesFolder -ItemType Directory | Out-Null
    }
    return $cachedProfilesFolder
}
Function Get-CachedProfile {
    param(
        [string] $name = $null
    )
    Get-Profile -Name $name -Folder (Get-CachedPowerShellProfileFolder)
}
Function Get-CachedProfilePath {
    param(
        [string] $name = $null
    )
    Get-ProfilePath -Name $name -Folder (Get-CachedPowerShellProfileFolder)
}
Function Get-CachedProfileUpdatePath {
    param(
        [string] $name = $null
    )
    $cachedProfilesFolder = Get-CachedPowerShellProfileFolder
    $cachedProfileUpdateFile = [IO.Path]::Combine($cachedProfilesFolder, "$($name)_update.txt")

    return $cachedProfileUpdateFile
}
Function Get-DefaultProfile {
    $___profile = Join-Path -Path (Split-Path -Path $profile -Parent) -ChildPath "profile.ps1"
    Write-Output $___profile
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
    
            try { irm -Method HEAD -Uri $uri -Verbose:$false | Out-Null } catch { return $false }
            return $true
        }
    }
    
    PROCESS {
    
        if (-not $name) { $name = "profile" }
    
        if ($remote.IsPresent) {
    
            $profilePath = Get-ProfilePath -Name $name -Remote
            if (-not (Test-WebPath -Uri $profilePath)) {
                $profilePath = Get-ProfilePath -Name $name -Alternate -Remote
                if (-not (Test-WebPath -Uri $profilePath)) { return }
            }
        }
    
        else {
    
            ## Using [IO.File]::Exists() instead of Test-Path for performance purposes
    
            $profilePath = Get-ProfilePath -Name $name -Folder $folder -Alternate
            if (-not ([IO.File]::Exists($profilePath))) {
                $profilePath = Get-ProfilePath -Name $name -Folder $folder
                if (-not ([IO.File]::Exists($profilePath))) { return }
            }
        }
    
        Write-Output $profilePath
    }
}             
Function Get-ProfilePath {
    [CmdletBinding(DefaultParameterSetName = "Path")]
    param(
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "Path")]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "Remote")]
        [string] $name = $null,
    
        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = "Path")]
        [string] $folder = (Split-Path $profile -Parent),
    
        [Parameter(ParameterSetName = "Remote")]
        [switch] $remote,

        [Parameter(ParameterSetName = "Path")]
        [Parameter(ParameterSetName = "Remote")]
        [switch] $alternate
    )
    
    BEGIN {
        $pattern = (Split-Path $profile -Leaf)
    
        $template = "Microsoft.PowerShell_%{NAME}%profile.ps1"
        $address = "https://raw.githubusercontent.com/springcomp/powershell_profile.ps1/master/"
    }

    PROCESS {

        if (-not $name) { $name = "profile" }
    
        if ($remote.IsPresent) {

            if ($alternate.IsPresent) {
                $fileName = $pattern.Replace("profile", "$name-profile")
                $profilePath = "$($address)$($fileName)"
            }
            else {
                $fileName = $pattern.Replace("profile", "$name")
                $profilePath = "$($address)$($fileName)"
            }
        }
    
        else {
    
            ## Using [IO.Path]::Combine() instead of Join-Path for performance purposes

            if ($alternate.IsPresent) {
                $fileName = $pattern.Replace("profile", $name)
                $profilePath = [IO.Path]::Combine($folder, $fileName)
            }
            else {
                $fileName = $pattern.Replace("profile", "$name-profile")
                $profilePath = [IO.Path]::Combine($folder, $fileName)
            }
        }
    
        Write-Output $profilePath
    }
}
Function Get-ProfileVersion {
    [CmdletBinding()]
    param( [string]$name, [switch]$remote )

    if ($remote.IsPresent) {
    
        $address = Get-Profile -Name $name -Remote
        if (-not $address) { return "0.0.0000.00000" }
    
        $line = (irm -Method Get -Uri $address -Verbose:$false).Split("`n") |`
            Select-Object -First 1
    }
    else {
    
        $currentProfile = Get-Profile -Name $name
        if (-not $currentProfile) { return "0.0.0000.00000" }
        $line = Get-Content -Path $currentProfile |`
            Select-Object -First 1
    }

    $pattern = "^#\s*(?<ver>\d+\.\d+(?:\.\d{4}){2}\d)\s*`$"
    $matches = ($line -match $pattern)
    if (-not ($line -match $pattern)) {
        return "0.0.0000.00000"
    }

    return $matches["ver"]
}
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
            if (($state -eq 1) -and ($line -match "")) { $nextState = 2 }
            if (($state -eq 2) -and ($line -match "## SECURITY - SENSITIVE DATA")) { $nextState = 3 }
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
                        $before += $line
                    }
                    2 {
                        if ($line.Length -gt 0) {
                            if ($nextState -eq 3) {
                                $after += ""
                                $after += $line
                            }
                            else { $content += $line }
                        }
                    }
                    3 {
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

            # $lines[0] is $before
            # $lines[1] is $content
            # $lines[2] is $after

            $lines[1] += $newLine
            $lines[1] = $lines[1] | Sort-Object

            Clear-Content -Path $profiles 
            $lines |% { $_ |% { Add-Content -Path $profiles -Value $_ }}
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

        CheckFor-ProfileUpdate -Name $name
    }
}

# Windows PowerShell (5.x) has conflicting alias "lp" for "Out-Printer"
if ([bool] (Get-Alias -Name lp -EA SilentlyContinue |? { $_.ResolvedCommand.Name -eq "Out-Printer"  })) { Remove-Item -Path "alias:\lp" }
Set-Alias -Name lp -Value Load-Profile
Set-Alias -Name up -Value Update-Profile

Function Remove-DefaultProfile {
    $___profile = Get-DefaultProfile
    if (Test-Path $___profile) { 
        Write-Host "Removing default profile file." -ForegroundColor Yellow
        Remove-Item $___profile -Force
    }
}
Function Set-LastUpdatedProfile {
    [CmdletBinding()]
    param( [string]$name = "", [DateTime]$dateTime = [DateTime]::UtcNow )
    
    $cachedProfileUpdateFile = Get-CachedProfileUpdatePath -Name $name
    $timestamp = $dateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
    
    Set-Content `
        -Path $cachedProfileUpdateFile `
        -Value $timestamp
}
Function Update-Profile {
    param ( [string]$name = "", [switch]$reload )
    Download-Profile -Name $name -Force -Load:$reload
    Set-LastUpdatedProfile -Name $name
}

## 

CheckFor-ProfileUpdate
Load-Profile "profiles" -Quiet
