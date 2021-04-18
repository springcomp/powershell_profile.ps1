$__VIM_HOME="D:\Users\mlabelle\AppData\Local\Programs\Git\usr\bin"

Add-DirectoryToPath -Path $__VIM_HOME

function vim {
    . "$($__VIM_HOME)\vim.exe" $args
}
Set-Alias -Name vi -Value vim