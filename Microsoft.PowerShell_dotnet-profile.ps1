# 1.0.7992.37994

[CmdletBinding()]
param( [switch] $completions )

"C:\Program Files\Microsoft Visual Studio\2022\Preview\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator", `
    "C:\Program Files\Microsoft Visual Studio\2022\Preview\Common7\IDE", `
    "C:\Program Files\Microsoft Visual Studio\2022\Preview\MSBuild\Current\Bin\amd64", `
    "C:\Portable Apps\IlSpy" | Add-DirectoryToPath

if ($completions.IsPresent) {

    Write-Host "Loading CLI completions for dotnet." -Foreground Darkgray 

    # PowerShell parameter completion shim for the dotnet CLI 
    Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
        param($commandName, $wordToComplete, $cursorPosition)
        dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
}

$Env:PROJECT_DIRECTORY = Join-Path -Path ([IO.Path]::GetPathRoot($Env:USERPROFILE)) -ChildPath "Projects"
Function me { Push-Location ([IO.Path]::Combine($Env:PROJECT_DIRECTORY, "springcomp")) }
Function pro { Set-Location $Env:PROJECT_DIRECTORY }
Function run-tests {
    param([string]$pattern = "*Tests.csproj")
    Get-ChildItem -Path $PATH -Recurse -Filter $pattern | % { dotnet test $_.FullName }
}
Function vs {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("Solution")]
        [Alias("Fullname")]
        [Alias("PSPath")]
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