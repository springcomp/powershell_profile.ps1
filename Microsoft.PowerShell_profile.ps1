
$_paths = `
    "C:\Program Files\Git\usr\bin\", `
    "C:\Program Files (x86)\GnuPG\bin", `
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\Tools", `
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\amd64", `
    "C:\Portable Apps\ILSpy"

$_joinedpaths = [String]::Join(";", $_paths)
if (-not (Test-Path env:\PATH_ORIG)) {
    $Env:PATH_ORIG = $Env:PATH
}

$Env:PATH = "$Env:PATH_ORIG;$_joinedpaths"
$Env:GNUPGHOME = "$Env:APPDATA\GnuPG"

## SECURITY - SENSITIVE DATA

$secrets = $profile.Replace("profile", "secret-profile")
Write-Host $secrets
if (Test-Path -Path $secrets){
    Write-Host "Loading sensitive data from $($secrets)"
    . $secrets
}

## SENSITIVE DATA

Function c {
    param([string] $path = ".")
    . code $path
}
Function b64 {
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$inputObject
    )
    PROCESS {
        $base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($inputObject))
        Write-Output $base64
    }
}
Function add { git add $args }
Function clone { git clone --recurse-submodules $args }
Function commit { git commit $args }
Function cguid { [Guid]::NewGuid().guid | clipp }
Function cwd { $PWD.Path | clipp }
Function ewd { param([string] $path = $PWD.Path) explorer $path }
Set-Alias -Name e -Value ewd
Function feature {
    param(
        [string]$feature
    )

    if ($feature.Length -gt 0) {
        feature-start -feature $feature
    }
    else {
        $branch = $(git rev-parse --abbrev-ref HEAD)
        $feature = $branch.Replace("feature/", "")
        Write-Output $feature
    }
}
Function feature-start {
    param(
        [string]$feature
    )
    git flow feature start $feature
}
Function feature-publish {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    $feature = $branch.Replace("feature/", "")
    git flow feature publish $feature
}
Function feature-finish {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    $feature = $branch.Replace("feature/", "")
    git flow feature finish $feature
}
Function filezilla { & 'C:\Portable Apps\FileZilla\FileZillaPortable.exe' }
Set-Alias -Name zilla -Value filezilla
Function Get-CurrentVersion {
 $epoch = [DateTime]::Parse("2000-01-01")
  $now = Get-Date
  $build = [Math]::Floor(($now - $epoch).TotalDays)
  $rev = [Math]::Floor(($now - $now.Date).TotalSeconds / 2)
  Write-Output "1.0.$($build).$($rev)"
}
Function g { git status }
Function lol { git log --oneline --decorate --graph }
Function pro { Set-Location C:\Projects }
Function pull { git fetch -p; git merge --ff-only }
Function push { git push $args }
Function reset {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias("FullName")]
        [string]$path
    )
    PROCESS{
        git checkout HEAD -- $path
    }
}
Function run-tests { Get-ChildItem -Path $PATH -Recurse -Filter *Tests.csproj |% { dotnet test $_.FullName } }
Function Search-Item {
    [CmdletBinding()]
    param(
        [string]$path = $PWD,
        [string]$filter = "*.*"
    )

    Get-ChildItem -Path $path -Recurse -Filter $filter -EA SilentlyContinue | % {
        Write-Output $_.FullName
    }
}

Set-Alias -Name search -Value Search-Item

Function sshlinux { param([string]$username = "maxime") PROCESS { ssh -i $Env:USERPROFILE\.ssh\$userName.key $userName`@40.85.93.164 $args } }
Function sshdown { param([string]$source, [string]$target) scp -i $Env:USERPROFILE\.ssh\maxime.key "maxime@40.85.93.164:$source" "$target" }
Function sshup { param([string]$source, [string]$target, [string] $username = "maxime") scp -i $Env:USERPROFILE\.ssh\$username.key $source "$username@40.85.93.164:$target" }
Function ub64 {
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$inputObject
    )
    PROCESS {
        $buffer = [Convert]::FromBase64String($inputObject)
        $text = [Text.Encoding]::UTF8.GetString($buffer)
        Write-Output $text
    }
}