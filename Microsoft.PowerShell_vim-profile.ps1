Add-DirectoryToPath -Path "C:\Program Files (x86)\Vim\vim81"

function vim {
    . "C:\Program Files (x86)\Vim\vim81\vim.exe" $args
}
Set-Alias -Name vi -Value vim