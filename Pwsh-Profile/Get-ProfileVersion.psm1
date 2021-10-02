Function Get-ProfileVersion {
    [CmdletBinding()]
    param( [string]$name, [switch]$remote )

    BEGIN {
        $DEFAUT_VERSION = "0.0.0000.00000"
    }

    PROCESS {

        if ($remote.IsPresent) {
        
            $address = Get-Profile -Name $name -Remote
            if (-not $address) { return $DEFAULT_VERSION}
        
            try {
                $line = (irm -Method Get -Uri $address -TimeoutSec 2 -Verbose:$false).Split("`n") |`
                    Select-Object -First 1
            }
            catch { return $DEFAULT_VERSION}
        }
        else {
        
            $currentProfile = Get-Profile -Name $name
            if (-not $currentProfile) { return $DEFAULT_VERSION}
            $line = Get-Content -Path $currentProfile |`
                Select-Object -First 1
        }

        $pattern = "^#\s*(?<ver>\d+\.\d+(?:\.\d{4}){2}\d)\s*`$"
        $matches = ($line -match $pattern)
        if (-not ($line -match $pattern)) {
            return $DEFAULT_VERSION
        }

        return $matches["ver"]
    }
}
