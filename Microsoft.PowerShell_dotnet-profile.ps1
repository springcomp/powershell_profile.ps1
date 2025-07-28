# 1.0.8036.30867

[CmdletBinding()]
param( [switch] $completions )

$VS_DIR__="C:\Program Files\Microsoft Visual Studio\2022"

"$($VS_DIR__)\Community\MSBuild\Current\Bin\amd64", `
    "$($VS_DIR__)\Professional\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator", `
    "$($VS_DIR__)\Professional\Common7\IDE", `
    "$($VS_DIR__)\Professional\MSBuild\Current\Bin\amd64", `
    "C:\Portable Apps\IlSpy", `
    "C:\Program Files (x86)\GitHub CLI" |? { Test-Path $_ } | Add-DirectoryToPath

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
    [CmdletBinding()]
    param(
        [string]$pattern = "*Tests.csproj",
        [Alias("html")]
        [switch]$visual
    )
    Get-ChildItem -Path $PATH -Recurse -Filter $pattern | % {
        run-test -Path $_.FullName `
            -Html:$visual
    }
}
Function run-test {
    [CmdletBinding()]
    param(
        [string]$path,
        [Alias("html")]
        [switch]$visual
    )

    $projectDir = Split-Path -Path $path
    $resultsDir = Join-Path -Path $projectDir -ChildPath "TestResults"

    dotnet test $path `
    	--collect:"Code Coverage" `
    	--results-directory:"$resultsDir"

    # find test results
    if (-not (Test-Path -Path $resultsDir)) {
    	Write-Host "Missing test results" -ForegroundColor Red
    	return 
    }
    $collectedDir = (Get-ChildItem -Path $resultsDir |`
    	Sort-Object -Property LastWriteTime |`
    	Select-Object -First 1).FullName

    if (-not $collectedDir) {
    	Write-Host "Missing collected code coverage" -ForegroundColor Red
    	return 
    }

    $coverage = Get-ChildItem -Path $collectedDir -Filter "*.coverage" |`
    	Select-Object -First 1

    if (-not $coverage) {
    	Write-Host "Missing collected code coverage output" -ForegroundColor Red
    	return 
    }

    dotnet coverage merge $coverage `
    	--output $collectedDir/output.xml `
    	--output-format xml `
    	--disable-console-output

    reportgenerator `
    	-reports:"$collectedDir/output.xml" `
    	-targetdir:"$collectedDir/coveragereport" `
    	-reporttypes:Html `
    	-verbosity:Error

    if ($visual.IsPresent) {
    	start "$collectedDir/coveragereport/Index.html"
    }

    reportgenerator `
    	-reports:"$collectedDir/output.xml" `
    	-targetdir:"$collectedDir/coveragereport" `
    	-reporttypes:TextSummary `
    	-verbosity:Off

    Write-Host (Get-Content -Raw -Path "$collectedDir/coveragereport/Summary.txt")
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