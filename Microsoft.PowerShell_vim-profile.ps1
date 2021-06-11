Add-DirectoryToPath -Path "D:\Users\mlabelle\AppData\Local\Programs\Git\usr\bin"

function vim {
    . "D:\Users\mlabelle\AppData\Local\Programs\Git\usr\bin\vim.exe" $args
}
Set-Alias -Name vi -Value vim