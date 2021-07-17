## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "D:\Projects\springcomp\clip\src\clip\bin\Debug"

$_paths | Add-DirectoryToPath 