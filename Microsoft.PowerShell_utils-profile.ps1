# 1.0.8467.24195

if ($null -eq (Test-Command "clipp")) {
    Function clipp {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromPipeline = $true)]
            [string]$text = $null,

            [Parameter(Mandatory = $false, Position = 0)]
            [Alias("PSPath")]
            [Alias("FullName")]
            [string]$path = $null
        )

        PROCESS {
            if ((-not $text) -and (-not $path)) { . "CLIP.EXE" }
            else {
                if ([bool] $path) { Get-Content -Path $path | . "CLIP.EXE" }
                if ([bool] $text) { $text | . "CLIP.EXE" }
            }
        }
    }
}

Function c {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [Alias("FullName")]
        [string] $path = "."
    )
    . code $path
}
Function ccv { Get-CurrentVersion | clipp }
Function cguid {
    param([string]$facet = "d")
    [Guid]::NewGuid().ToString($facet) | clipp
}
Function cwd { $PWD.Path | clipp }
Function csp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$path = $profile
    )
    code (split-path -path "$path")
}

Function d2u {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Fullname")]
        [string]$path
    )

    PROCESS {

        $arr = Get-Content -Path $path
        Set-Content `
            -Path $path `
            -Encoding UTF8 `
            -Value (
            [String]::Join("`n", $arr)
        )
    }
}
Function trunc {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Fullname")]
        [string]$path
    )
    	
    PROCESS {
        $arr = Get-Content -Path $path

        $lastLine = $arr.Length
        $stop = $false
        for ($index = $arr.Length - 1; $index -ge 0; $index = $index - 1) {
            $line = $arr[$index].Trim()
            if ($line.Length -ne 0) { $stop = $true }
            if (($line.Length -eq 0) -and (-not $stop)) {
                $lastLine = $index
            }
        }
        $arr = $arr | Select-Object -First $lastLine

        Set-Content `
            -Path $path `
            -Encoding UTF8 `
            -Value ([String]::Join([Environment]::NewLine, $arr))
    }
}
Function u2d {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Fullname")]
        [string]$path
    )

    PROCESS {

        $arr = Get-Content -Path $path
        Set-Content `
            -Path $path `
            -Encoding UTF8 `
            -Value (
            [String]::Join("`r`n", $arr)
        )
    }
}
Function esp { explorer (split-path $args) }
Function ewd {
    param([string] $path = $PWD.Path)
    if ($path.EndsWith("\")) {
        $path = $path.Substring(0, $path.Length - 1)
    }
    explorer $path 
}
Set-Alias -Name e -Value ewd
Function filezilla { & 'C:\Portable Apps\FileZilla\FileZillaPortable.exe' }
Set-Alias -Name zilla -Value filezilla
Function Get-CurrentVersion {
    $epoch = [DateTime]::Parse("2000-01-01")
    $now = Get-Date
    $build = [Math]::Floor(($now - $epoch).TotalDays)
    $rev = [Math]::Floor(($now - $now.Date).TotalSeconds / 2)
    Write-Output "1.0.$($build).$($rev)"
}
Set-Alias -Name gcv -Value Get-CurrentVersion
Function izarc { & 'C:\Portable Apps\IZarc2Go\IZArc2Go.exe' }
Function keepass { & 'C:\Portable Apps\KeePass\KeePass.exe' }
Set-Alias -Name kp -Value keepass

Function mkcdir {
    param([string]$path)
    if (-not $path) { return }
    New-Item -Path $path -ItemType Directory -EA SilentlyContinue | Out-Null
    if (Test-Path -Path $path) { Set-Location -Path $path }
}

Function rmf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [Alias("FullName")]
        [string]$path
    )
    PROCESS {
        Remove-Item `
            -Path $path `
            -Recurse `
            -Force `
            -EA SilentlyContinue
    }
}
Function servicebus {
    Push-Location -Path $Env:TEMP\
    & 'C:\Portable Apps\ServiceBus Explorer\ServiceBusExplorer.exe'
    Pop-Location
}
Set-Alias -Name sbex -Value servicebus
