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
        $DEFAULT_REMOTE_REPOSITORY = "https://raw.githubusercontent.com/springcomp/powershell_profile.ps1/master/"
        $address = $Env:PWSH_PROFILES_REMOTE_REPOSITORY
        if (-not $address) {
            $address = $DEFAULT_REMOTE_REPOSITORY
        }
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
