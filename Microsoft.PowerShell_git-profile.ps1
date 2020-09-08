Add-DirectoryToPath -Path "C:\Program Files\Git\usr\bin\"

Function add { git add $args }
Function clone { git clone --recurse-submodules $args }
Function commit { git commit $args }
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
Function g { git status }
Function lol { git log --oneline --decorate --graph }
Function pull { git fetch -p; git merge --ff-only }
Function push { git push $args }
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