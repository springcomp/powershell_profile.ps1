## Well-known profiles script
Function Load-Profile {
    [CmdletBinding()]
    param(
        [string] $name
    )

    BEGIN {

        Function Get-PwshExpression {
            param([string]$path)

            $content = Get-Content -Path $path -Raw
            $content = $content -replace "[Ff]unction\ +([A-Za-z])", "Function global:`$1"
            $content = $content -replace "[Ss][Ee][Tt]\-[Aa][Ll][Ii][Aa][Ss]\ +(.*)$", "Set-Alias -Scope Global `$1"

            Write-Output $content
        }
    }

    PROCESS {

        $alternate = $profile.Replace("profile", $name)
        if (Test-Path -Path $alternate) {
            Write-Host "Loading $name profile." -ForegroundColor Gray
            Invoke-Expression -Command (Get-PwshExpression -Path $alternate)
        }
        else {

            $alternate = $profile.Replace("profile", "$name-profile")
            if (Test-Path -Path $alternate) {
                Write-Host "Loading $name profile." -ForegroundColor Gray
                Invoke-Expression -Command (Get-PwshExpression -Path $alternate)
            }
            else {
                Write-Host "No such profile '$name'." -ForegroundColor Magenta
            }
        }
    }
}

Load-Profile "base"
Load-Profile "b64"
Load-Profile "dotnet"
Load-Profile "git"

## Setup PATH environment variable

$_paths = `
    "C:\Program Files (x86)\GnuPG\bin", `
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\Tools", `
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\amd64", `
    "$Env:LOCALAPPDATA\Programs\Python\Python38-32", `
    "$Env:LOCALAPPDATA\Programs\Python\Python38-32\Scripts", `
    "C:\Portable Apps\ILSpy"

$_paths | Add-DirectoryToPath 

$Env:GNUPGHOME = "$Env:APPDATA\GnuPG"

## SECURITY - SENSITIVE DATA

Load-Profile "secret"

## SENSITIVE DATA

Function c {
    param([string] $path = ".")
    . code $path
}
Function cguid { [Guid]::NewGuid().guid | clipp }
Function cwd { $PWD.Path | clipp }
Function ewd { param([string] $path = $PWD.Path) explorer $path }
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