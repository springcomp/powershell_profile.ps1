$CHOCO_HOME = "C:\ProgramData\chocolatey"

"$CHOCO_HOME\lib\mpv.install\tools", `
"$CHOCO_HOME\lib\f1viewer\tools", `
"$CHOCO_HOME" `
    | Add-DirectoryToPath
