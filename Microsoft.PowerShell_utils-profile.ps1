
Function c {
    param([string] $path = ".")
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

Function rmf {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [Alias("FullName")]
        [string]$path
    )
    Remove-Item `
        -Path $path `
        -Recurse `
        -Force 
}
Function Search-Item {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [Alias("pattern")]
        [string]$filter = "*.*",

        [Parameter(Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [Alias("PSPath")]
        [string]$path = $PWD

    )

    PROCESS {

        Write-Host "Searching in $path"

        Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | ForEach-Object {
            Write-Output $_.FullName
        }
    }
}

Set-Alias -Name search -Value Search-Item
Function servicebus { & 'C:\Portable Apps\ServiceBus Explorer\ServiceBusExplorer.exe' }
Set-Alias -Name sbex -Value servicebus

Function Upgrade-PowerShell {
    Remove-Item -Path "$Env:LOCALAPPDATA\Microsoft\powershell-daily" -Recurse -Force -EA SilentlyContinue
    Copy-Item -Path "$Env:LOCALAPPDATA\Microsoft\powershell-daily.old\assets" -Destination "$Env:LOCALAPPDATA\Microsoft\powershell-daily\assets" -Recurse
    Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -daily"
}
Set-Alias -Name update -Value Upgrade-PowerShell