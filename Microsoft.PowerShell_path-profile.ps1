## Setup PATH environment variable

$_paths = `
    "C:\Portable Apps", `
    "C:\Projects\springcomp\clip\src\clip\bin\Release"

$_paths | Add-DirectoryToPath 

