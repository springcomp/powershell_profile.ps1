Function pro { Set-Location C:\Projects }
Function run-tests { Get-ChildItem -Path $PWD -Recurse -Filter *Tests.csproj | % { dotnet test $_.FullName } }