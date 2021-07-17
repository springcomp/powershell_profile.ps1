[CmdletBinding()]
param( [switch] $completions )

"C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\Common7\IDE", `
    "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin", `
    "C:\Portable Apps\IlSpy" | Add-DirectoryToPath

if ($completions.IsPresent) {
    # PowerShell parameter completion shim for the dotnet CLI 
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

$Env:PROJECT_DIRECTORY = Join-Path -Path ([IO.Path]::GetPathRoot($Env:USERPROFILE)) -ChildPath "Projects"
Function me { Set-Location ([IO.Path]::Combine($Env:PROJECT_DIRECTORY, "springcomp")) }
Function pro { Set-Location $Env:PROJECT_DIRECTORY }
Function run-tests { Get-ChildItem -Path $PATH -Recurse -Filter *Tests.csproj | % { dotnet test $_.FullName } }
Function vs {
    [CmdletBinding()]
    param(
        [Alias("Solution")]
        [string]$path = $null
    )

    if (-not $path) {
        $solution = Get-ChildItem -Path $PWD -Filter "*.sln" | Select-Object -First 1
    } else {
        $solution = Get-Item -Path $path
    }

    Write-Host $solution

    if ($solution) { & devenv.exe $solution.FullName }
    else {
        $project = Get-ChildItem -Path $PWD -Filter "*.csproj" | Select-Object -First 1
        Write-Host $project
        if ($project) { & devenv.exe $project.FullName }
        else {
            Write-Host "Launching Visual Studio"
            & devenv.exe $args 
        }
    }
}