# 1.0.7979.15913

[CmdletBinding()]
param( [switch]$completions )


if ($completions.IsPresent) {

    Write-Host "Loading CLI completions for git." -ForegroundColor Cyan

    ## CLI completions require Git bash

    $__GIT_HOME=Join-Path -Path (Split-Path (Split-Path -Path (Get-Command "git").Source)) -ChildPath "bin"
    $__GIT_HOME | Add-DirectoryToPath -Prepend

    Function Has-Module {
        param([string]$name)
        return [bool] (Get-Module -ListAvailable -Name $name)
    }

    Function Install-GitCompletion {
        [CmdletBinding()]
        param([Alias("CompletionsPath")][string]$path)
        Install-Module -Name PSBashCompletions -Scope CurrentUser -Force
        New-Item -Path $path -ItemType Directory -EA SilentlyContinue | Out-Null
        $completions = "https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash"
        Invoke-WebRequest -Method Get $completions -OutFile $path/git.sh
    }

    $completionsPath = Join-Path (Split-Path -Parent $PROFILE) Completions
    if ((-not (Has-Module PSBashCompletions)) -or (-not (Test-Path $completionsPath/git.sh))) {
        Install-GitCompletion -Completions $completionsPath
    }

    if (Test-Path $completionsPath) {
        if (Get-Module -Name PSBashCompletions -ListAvailable){
            Import-Module -Name PSBashCompletions
            Register-BashArgumentCompleter git "$completionsPath/git.sh"
        }
    }
}

Function add { git add $args }
Function amend { git commit --amend $args }
Function append { git commit --amend --no-edit $args }
Function clone { git clone --recurse-submodules $args }
Function commit { git commit $args }
Function feature {
    param(
        [string]$feature
    )

    if ($feature.Length -gt 0) {
        if ($feature -eq "publish") { & feature-publish }
        if ($feature -eq "finish") { & feature-finish }
        else { feature-start -feature $feature }
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
Function fetch { git fetch --all -p $args }
Function g { git status }
Function lol { git log --oneline --decorate --graph $args }
Function pull { git fetch -p; git merge --ff-only }
Function push { git push $args }

Function pushup {
    param(
        [string]$remote = "origin",
        [switch]$force
    )
    $branch = $(git rev-parse --abbrev-ref HEAD)
    if ($force.IsPresent) {
        git push --set-upstream $remote $branch --force
    }
    else {
        git push --set-upstream $remote $branch
    }
}
Function release-start {
    param(
        [string]$release
    )
    git flow release start $release
}
Function release-publish {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    $release = $branch.Replace("release/", "")
    git flow release publish $release
}
Function release-finish {
    $branch = $(git rev-parse --abbrev-ref HEAD)
    $release = $branch.Replace("release/", "")
    git flow release finish $release
}
## Usage: `remote`: displays the current remote endpoint.
## Usage: `remote <path>`: displays the remote endpoint to a given local git repository
## Usage: `remote $args`: runs `git remote $args`
Function remote {

    if (($args.Length -eq 1) -and (Test-Path -Path $args[0])){
        $path = $args[0]
        pushd $path; iex ". remote"; popd
        return
    }
    
    if (-not $args) {
        git remote -v |? { $_ -match "(fetch)" } |`
            Select-Object -First 1 |% {
                $_ -replace "^(?<remote>[^\t\ ]+)\t+(?<uri>[^\ ]+)\ \(fetch\)`$", "`$2"
            }
    } else {
        git remote $args
    }
}
Function reset {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias("FullName")]
        [string]$path
    )
    PROCESS {
        git checkout HEAD -- $path
    }
}
Function undo_redo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias("FullName")]
        [string]$path,
        [string]$comment = "undo"
    )
    PROCESS {
        git checkout HEAD^1 -- "$path"
        git add $path
        git commit -m "$($comment): $($path)"
    }
}
Function undo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias("FullName")]
        [string]$path
    )
    PROCESS { undo_redo -path $path }
}
Function redo {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [Alias("FullName")]
        [string]$path
    )
    PROCESS { undo_redo -path $path -comment "redo" }
}