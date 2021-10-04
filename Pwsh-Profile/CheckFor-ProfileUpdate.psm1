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
            $timestamp = $timestamp.ToUniversalTime()
            return $timestamp
        }
        Function Needs-Update {
            [CmdletBinding()]
            param( [string]$name )

            $DEFAULT_CHECK_FOR_UPDATES_FREQUENCY_IN_DAYS = 1
            $checkForUpdatesFrequencyInDays = $Env:CHECK_FOR_PWSH_PROFILE_UPDATES_FREQUENCY_IN_DAYS
            if (-not $checkForUpdatesFrequencyInDays) {
                $checkForUpdatesFrequencyInDays = $DEFAULT_CHECK_FOR_UPDATES_FREQUENCY_IN_DAYS
            }

            $lastUpdated = Get-LastUpdated -Name $name
            $now = (Get-Date).ToUniversalTime()

            Write-Verbose "$($name): Last updated: $lastUpdated; Now: $now."
            Write-Verbose "$($name): Last updated: $(($now - $lastUpdated).TotalDays) days ago."
            Write-Verbose "$($name): Checking for updates every $checkForUpdatesFrequencyInDays days."
            Write-Verbose "$($name): Do we need to check for updates: $(($now - $lastUpdated).TotalDays -gt $checkForUpdatesFrequencyInDays)."

            if (($now - $lastUpdated).TotalDays -gt $checkForUpdatesFrequencyInDays) {
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

            return $true
        }

        return $false
    }
}
