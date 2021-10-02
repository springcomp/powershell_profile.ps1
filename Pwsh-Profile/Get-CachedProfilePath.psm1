Function Get-CachedProfilePath {
    param(
        [string] $name = $null
    )
    Get-ProfilePath -Name $name -Folder (Get-CachedPowerShellProfileFolder)
}
