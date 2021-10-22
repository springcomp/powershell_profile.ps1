# 1.0.7965.13927

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
Function cguid { [Guid]::NewGuid().guid | clipp }
Function cwd { $PWD.Path | clipp }
Function csp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$path = $profile
    )
    code (split-path -path "$path")
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
