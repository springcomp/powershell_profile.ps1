 "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE", `
 "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin", `
 "C:\Portable Apps\IlSpy\IlSpy.exe" | Add-DirectoryToPath

Function me { Set-Location D:\Projects\springcomp }
Function pro { Set-Location D:\Projects }
Function run-tests { Get-ChildItem -Path $PATH -Recurse -Filter *Tests.csproj | % { dotnet test $_.FullName } }

Function vs { & devenv.exe $args }