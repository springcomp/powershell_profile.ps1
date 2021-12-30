# 1.0.8034.16356

## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "C:\Projects\springcomp\clip\src\clip\bin\Release"

$_paths | Add-DirectoryToPath -Prepend