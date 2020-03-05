
Function Add-DirectoryToPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [string] $path,

        [switch] $whatIf
    )

    BEGIN {

        ## normalize paths

        $paths = @()
        $env:PATH.Split(";") | ForEach-Object {
            if ($_.Length -gt 0) {
                $paths += $_.ToLowerInvariant()
            }
        }

        Function Array-Contains {
            param(
                [string[]] $array,
                [string] $item
            )

            $any = $array | Where-Object -FilterScript {
                $_ -eq $item
            }

            Write-Output ($null -ne $any)
        }
    }

    PROCESS {

        $path = $path -replace "^(.*);+$", "`$1"
        $path = $path -replace "^(.*)\\$", "`$1"
        if (Test-Path -Path $path) {
            $path = (Resolve-Path -Path $path).Path
            $path = $path.Trim()

            $newPath = $path.ToLowerInvariant()
            if (-not (Array-Contains -Array $paths -Item $newPath)) {
                if ($whatIf.IsPresent) {
                    Write-Host $path
                }
                $paths += $path
            }
        }
        else {

            Write-Host "Invalid entry in `$Env:PATH: ``$path``" -ForegroundColor Yellow

        }
    }

    END {

        ## re-create PATH environment variable

        $joinedPaths = [string]::Join(";", $paths)
        $envPATH = "$($env:PATH)$($joinedpaths)"

        if ($whatIf.IsPresent) {
            Write-Output $envPATH
        }
        else {
            $env:PATH = $envPATH
        }
    }
}

Function Search-Item {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [Alias("PSPath")]
        [string]$path = $PWD,

        [Parameter(Position = 0)]
        [Alias("pattern")]
        [string]$filter = "*.*"
    )

    PROCESS {

        Write-Host "Searching in $path"

        Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | ForEach-Object {
            Write-Output $_.FullName
        }
    }
}

Set-Alias -Name search -Value Search-Item