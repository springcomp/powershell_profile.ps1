## PowerShell Modules

$_module_paths = `
    "$Env:LOCALAPPDATA\Microsoft\Powershell-modules", `
    "$Env:LOCALAPPDATA\Microsoft\PowerShell-daily\Modules", `
    "C:\Program Files\PowerShell\Modules", `
    "C:\Program Files\WindowsPowerShell\Modules", `
    "C:\Windows\system32\WindowsPowerShell\v1.0\Modules"

$_module_paths | Add-DirectoryToPath -Clear -Force -Variable "PSModulePath"
