Function pro { Set-Location C:\Projects }
Function run-tests { Get-ChildItem -Path $PATH -Recurse -Filter *Tests.csproj | % { dotnet test $_.FullName } }