$__VIM_HOME="C:\Program Files\Git\usr\bin"

Add-DirectoryToPath -Path $__VIM_HOME

function vim {
    . "$($__VIM_HOME)\vim.exe" $args
}
Set-Alias -Name vi -Value vim