$__GIT_HOME="$Env:LOCALAPPDATA\Programs\Git"
"$__GIT_HOME\usr\bin" | Add-DirectoryToPath

function vim {
    . "vim.exe" $args
}
Set-Alias -Name vi -Value vim