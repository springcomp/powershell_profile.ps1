Function Install-Profile {
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$name,
        [switch]$load
    )

    BEGIN{

        $profiles = Split-Path $profile -Leaf
        $profiles = $profiles.Replace("profile", "profiles-profile")
        $profiles = Join-Path (Split-Path $profile) -ChildPath $profiles

        if (-not (Test-Path $profiles)) { New-Item -Path $profiles -ItemType File | Out-Null }

        Function Get-NextState {
            param(
                [string] $line,
                [int] $state
            )
            $nextState = $state
            if (($state -eq 0) -and ($line -match "## Load useful profiles")) { $nextState = 1 }
            if (($state -eq 1) -and ($line -match "")) { $nextState = 2 }
            if (($state -eq 2) -and ($line -match "## SECURITY - SENSITIVE DATA")) { $nextState = 3 }
            Write-Output $nextState
        }

        Function Get-LoadedProfiles {
            $before = @()
            $content = @()
            $after = @()
            $state = 0

            Get-Content -Path $profiles |? {

                $line = $_
                $nextState = Get-NextState -Line $line -State $state

                switch ($state) {
                    0 {
                        $before += $line
                    }
                    1 {
                        $before += $line
                    }
                    2 {
                        if ($line.Length -gt 0) {
                            if ($nextState -eq 3) {
                                $after += ""
                                $after += $line
                            }
                            else { $content += $line }
                        }
                    }
                    3 {
                        $after += $line
                    }
                }

                $state = $nextState
            }

            Write-Output $before, $content, $after
        }
    }
    PROCESS{

        if ($name -eq "profiles"){
            Write-Host "Cannot install `"profiles`" profile into itself." -ForegroundColor Red
            return 
        }

        $newLine = "Load-Profile `"$($name.ToLowerInvariant())`""

        if (Get-Content -Path $profiles |? { $_ -match $newLine }){
            Write-Host "Profile $name already registered to the profiles profile." -ForegroundColor Yellow
        } else {
            Update-Profile -Name $name -Reload:$load

            $lines = Get-LoadedProfiles 

            # $lines[0] is $before
            # $lines[1] is $content
            # $lines[2] is $after

            $lines[1] += $newLine
            $lines[1] = $lines[1] | Sort-Object

            Clear-Content -Path $profiles 
            $lines |% { $_ |% { Add-Content -Path $profiles -Value $_ }}
        }
    }
}
