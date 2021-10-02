Function Get-CachedProfile {
    param(
        [string] $name = $null
    )
    Get-Profile -Name $name -Folder (Get-CachedPowerShellProfileFolder)
}
