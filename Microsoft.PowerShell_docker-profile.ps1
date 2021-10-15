# 1.0.7958.38382

[CmdletBinding()]
param( [switch]$completions )

"C:\Portable Apps\Terraform", `
"C:\Portable Apps\Helm" `
    | Add-DirectoryToPath

if ($completions.IsPresent) {

    Write-Host "Loading CLI completions for docker | helm | kubectl." -ForegroundColor Cyan

    ## CLI completions require Git bash

    $__GIT_HOME=Join-Path -Path (Split-Path (Split-Path -Path (Get-Command "git").Source)) -ChildPath "bin"
    $__GIT_HOME | Add-DirectoryToPath -Prepend

    Function Has-Module {
        param([string]$name)
        return [bool] (Get-Module -ListAvailable -Name $name)
    }

    Function Install-KubeCompletion {
        [CmdletBinding()]
        param([Alias("CompletionsPath")][string]$path)
        Install-Module DockerCompletion -Scope CurrentUser -Force
        Install-Module -Name PSBashCompletions -Scope CurrentUser -Force
        New-Item -Path $path -ItemType Directory -EA SilentlyContinue | Out-Null
        ((kubectl completion bash) -join "`n") | Set-Content -Encoding ASCII -NoNewline -Path $path/kubectl.sh
        ((helm completion bash) -join "`n") | Set-Content -Encoding ASCII -NoNewline -Path $path/helm.sh
    }

    $completionsPath = Join-Path (Split-Path -Parent $PROFILE) Completions
    if (    (-not (Has-Module DockerCompletion)) `
        -or (-not (Has-Module PSBashCompletions)) `
        -or (-not (Test-Path $completionsPath/kubectl.sh)) `
        -or (-not (Test-Path $completionsPath/helm.sh))
        ) {
        Install-KubeCompletion -Completions $completionsPath
    }

    Import-Module DockerCompletion

    if (Test-Path $completionsPath) {
        Import-Module PSBashCompletions
        Register-BashArgumentCompleter kubectl "$completionsPath/kubectl.sh"
        Register-BashArgumentCompleter kc "$completionsPath/kubectl.sh"
        Register-BashArgumentCompleter helm "$completionsPath/helm.sh"
    }
}

Function tf-init {
    terraform init `
        -backend-config $PWD\tfbackend.tfvars
        $args
}
Function tf-plan {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform plan `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        $args
}
Function tf-apply {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform apply `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        -auto-approve `
        $args
}

Function tf-import {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform import `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        $args
}