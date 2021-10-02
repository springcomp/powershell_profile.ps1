Function Update-Profile {
    [CmdletBinding(DefaultParameterSetName = "Name")]
    param (
        [Parameter(ParameterSetName = "Name", Position = 0)]
        [string]$name = "",
        [Parameter(ParameterSetName = "All")]
        [switch]$all,
        [Parameter(ParameterSetName = "All")]
        [switch]$force,
        [switch]$reload
    )

    if ($all.IsPresent){
        Get-LoadedProfile |% {
            $profileName = $_
            if ($force.IsPresent -or (CheckFor-ProfileUpdate -Name $profileName)) {
                Update-Profile -Name $profileName -Reload:$reload
            }
        }
    }
    else {
        Download-Profile -Name $name -Force -Load:$reload
        Set-LastUpdatedProfile -Name $name
    }
}

Set-Alias -Name up -Value Update-Profile
