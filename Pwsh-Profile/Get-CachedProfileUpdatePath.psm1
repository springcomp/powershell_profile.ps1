Function Get-CachedProfileUpdatePath {
    param(
        [string] $name = $null
    )
    $cachedProfilesFolder = Get-CachedPowerShellProfileFolder
    $cachedProfileUpdateFile = [IO.Path]::Combine($cachedProfilesFolder, "$($name)_update.txt")

    return $cachedProfileUpdateFile
}
