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

        if (-not $uri) {
            Write-Host "No such profile '$name'." -ForegroundColor Yellow
            return
        }

        if (-not (Test-Path $destination) -or $force.IsPresent) {
            try {
                Invoke-RestMethod `
                    -Method Get `
                    -TimeoutSec 2 `
                    -Uri $uri `
                    -OutFile $destination
            }
            catch {
                Write-Host $_.Exception.Message -ForegroundColor Yellow
                return
            }
            
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
