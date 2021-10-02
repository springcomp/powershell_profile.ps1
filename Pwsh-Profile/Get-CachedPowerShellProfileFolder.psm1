Function Get-CachedPowerShellProfileFolder {
    $tempFolder = $Env:TEMP; if ($PSVersionTable.Platform -ne "Win32NT") { $tempFolder = "/tmp" }
    $cachedProfilesFolder = [IO.Path]::Combine($tempFolder, "PowerShell_profiles")
    if (-not ([IO.Directory]::Exists($cachedProfilesFolder))) {
        New-Item -Path $cachedProfilesFolder -ItemType Directory | Out-Null
    }
    return $cachedProfilesFolder
}

