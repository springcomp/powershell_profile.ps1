[CmdletBinding()]
param( [switch]$completions )

"C:\Portable Apps\Terraform", `
"C:\Portable Apps\Helm" `
    | Add-DirectoryToPath

if ($completions.IsPresent) {

    Write-Host "Loading CLI completions for docker | helm | kubectl." -ForegroundColor Cyan

    ## CLI completions require Git bash

    "d:\users\mlabelle\appdata\local\programs\git\bin" | Add-DirectoryToPath -Prepend

    ## Install-Module DockerCompletion -Scope CurrentUser
    Import-Module DockerCompletion

    ## Install-Module -Name PSBashCompletions -Scope CurrentUser
    ## $path = (mkdir (Join-Path (Split-Path -Parent $PROFILE) Completions)).FullName
    ## ((kubectl completion bash) -join "`n") | Set-Content -Encoding ASCII -NoNewline -Path $path/kubectl.sh
    ## ((helm completion bash) -join "`n") | Set-Content -Encoding ASCII -NoNewline -Path $path/helm.sh

    $completionsPath = Join-Path (Split-Path -Parent $PROFILE) Completions
    if (Test-Path $completionsPath) {
        Import-Module PSBashCompletions
        Register-BashArgumentCompleter kubectl "$completionsPath/kubectl.sh"
        Register-BashArgumentCompleter kc "$completionsPath/kubectl.sh"
        Register-BashArgumentCompleter helm "$completionsPath/helm.sh"
    }
}