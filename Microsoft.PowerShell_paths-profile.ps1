# 1.0.7945.32635

## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "C:\Projects\springcomp\clip\src\clip\bin\Release"

$_paths | Add-DirectoryToPath 