# 1.0.7936.40758

$__VIM_HOME=Join-Path -Path (Split-Path (Split-Path -Path (Get-Command "git").Source)) -ChildPath "usr\bin"

Add-DirectoryToPath -Path $__VIM_HOME

function vim {
    . "$($__VIM_HOME)\vim.exe" $args
}
Set-Alias -Name vi -Value vim