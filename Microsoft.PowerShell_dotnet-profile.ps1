# 1.0.9733.20165

[CmdletBinding()]
param( [switch] $completions )

$Env:NUGET_SOURCE="https://pkgs.dev.azure.com/${Env:ADO_ORG}/${Env:ADO_PROJ}/_packaging/IPaaS_Feed/nuget/v3/index.json"

$VS_DIR__="C:\Program Files\Microsoft Visual Studio\18"

"$($VS_DIR__)\Community\MSBuild\Current\Bin\amd64", `
    "$($VS_DIR__)\Community\Common7\IDE\Extensions\Microsoft\Azure Storage Emulator", `
    "$($VS_DIR__)\Community\Common7\IDE", `
    "$($VS_DIR__)\Community\MSBuild\Current\Bin\amd64", `
    "C:\Portable Apps\IlSpy" |? { Test-Path $_ } | Add-DirectoryToPath

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
        [Parameter(ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias("PSPath")]
        [string]$path,
        [Alias("html")]
        [switch]$visual
    )

    BEGIN {

        ## check required dotnet tools

        Function Get-DotNetTool {
            param([switch]$global)
            $command = "dotnet tool list"
            if ($global.IsPresent) { $command = $command + " --global" }
            $command += " --format json"
            $json = iex $command | ConvertFrom-JSON
            return $json.data
        }

        Function Ensure-DotNetTools {
            Ensure-DotNetTool -Path $path -PackageId "dotnet-coverage" -PackageVersion "17.14.2"
            Ensure-DotNetTool -Path $path -PackageId "dotnet-reportgenerator-globaltool" -PackageVersion "5.5.0"
        }

        Function Ensure-DotNetTool {
            param([string]$packageId, [string]$packageVersion)
            $array = Get-DotNetTool -Global |? { $_.packageId -eq $packageId -and $_.version -eq $packageVersion }
            if ((-not $array) -or ($array.Length -eq 0)) {
                Write-Verbose "Installing required dotnet tools"
                $command = "dotnet tool install --global --version `"$packageVersion`" `"$packageId`""
                iex $command
            }
        }

        Ensure-DotNetTools
    }

    PROCESS {

        Write-Verbose "Running $($path) tests"

        $path = (Resolve-Path -Path $path).Path

        if ((Get-Item -Path $path).PSIsContainer) {
            $projectDir = $path
        } else {
            $projectDir = Split-Path -Path $path -Parent
        }

        $resultsDir = Join-Path -Path $projectDir -ChildPath "TestResults"

        Write-Verbose "ProjectDir: $($projectDir)"
        Write-Verbose "ResultsDir: $($resultsDir)"

        dotnet test $path `
            --collect:"Code Coverage" `
            --results-directory:"$resultsDir"

        # find test results
        if (-not (Test-Path -Path $resultsDir)) {
            Write-Host "Missing test results" -ForegroundColor Red
            return 
        }
        $collectedDir = (Get-ChildItem -Path $resultsDir |? {
            (Get-ChildItem $_ | Measure-Object).Count -gt 0
        } | Sort-Object -Property LastWriteTime -Descending |`
            Select-Object -First 1).FullName

        Write-Verbose "CollectedDir: $($collectedDir)"

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

        Write-Verbose "Code coverage output: '$($collectedDir)/output.xml'"
        Write-Verbose "Code coverage summary: '$($collectedDir)/coveragereport/Summary.txt'"
        Write-Verbose "Code coverage report: '$($collectedDir)/coveragereport/Index.html'"
        Write-Host (Get-Content -Raw -Path "$collectedDir/coveragereport/Summary.txt")
    }
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
        $solution = Get-ChildItem -Path $PWD -Filter "*.sln?" | Select-Object -First 1
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
