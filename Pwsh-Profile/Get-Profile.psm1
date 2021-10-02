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
    
            try { irm -Method HEAD -Uri $uri -TimeoutSec 2 -Verbose:$false | Out-Null }
            catch { return $false }

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
