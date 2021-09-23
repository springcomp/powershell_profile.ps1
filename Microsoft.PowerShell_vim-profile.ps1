# 1.0.7936.41014

$__VIM_HOME=Join-Path -Path (Split-Path (Split-Path -Path (Get-Command "git").Source)) -ChildPath "usr\bin"

Add-DirectoryToPath -Path $__VIM_HOME

function vim { . vim.exe $args }
Set-Alias -Name vi -Value vim