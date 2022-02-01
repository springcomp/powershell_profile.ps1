# 1.0.8066.20885

[CmdletBinding()]
param( [switch]$completions )

"C:\Portable Apps\Helm" `
| Add-DirectoryToPath

$Env:DOCKER_HOST="tcp://localhost:2375"

Function Start-Docker {
    $ip = (wsl -d ubuntu-docker sh -c "hostname -I").Split(" ")[0]
    Write-Host "netsh interface portproxy add v4tov4 listenport=2375 connectport=2375 connectaddress=$ip"
    $arguments = "interface portproxy add v4tov4 listenport=2375 connectport=2375 connectaddress=$ip" 
    Start-Process netsh -ArgumentList $arguments -Verb RunAs
    Start-Job { param([string]$ip) wsl -d ubuntu-docker sh -c "sudo dockerd -H tcp://$ip" } -ArgumentList $ip | Out-Null
}
Set-Alias -Name dockerd -Value Start-Docker

Function Stop-Docker { wsl --terminate ubuntu-docker }
Set-Alias -Name rmdocker -Value Stop-Docker

Function Start-Kubernetes { wsl -d ubuntu-minikube sh -c "/home/kube/minikube.sh start --embed-certs" }
Set-Alias -Name k8s -Value Start-Kubernetes

Function Stop-Kubernetes { wsl --terminate ubuntu-minikube }
Set-Alias -Name rmkube -Value Stop-Kubernetes
Set-Alias -Name rmk8s -Value Stop-Kubernetes

Function kontrol { Start-Job { kubectl confluent dashboard controlcenter --namespace confluent } }
Function minikube { wsl -d ubuntu-minikube sh -c "/home/kube/minikube.sh $args" }

if ($completions.IsPresent) {

    Write-Host "Loading CLI completions for docker | helm | kubectl." -ForegroundColor Cyan

    Function Has-Module {
        param([string]$name)
        return [bool] (Get-Module -ListAvailable -Name $name)
    }

    ## This function is taken from
    ## https://github.com/springcomp/powershell_profile.ps1/blob/bb06eca65fda4d62c12269c8f770c562f8533c6c/Pwsh-Profile/Load-Profile.psm1#L14-L25
    ##
    ## TODO: allow module to run scripts in global scope instead of copying this function
    Function Get-PwshExpression {
        param([string]$path)

        ## Using [IO.File]::ReadAllText() instead of Get-Content -Raw for performance purposes

        $content = [IO.File]::ReadAllText($path)
        $content = $content -replace "(?<!\-)[Ff]unction\ +([_A-Za-z]+)", 'Function global:$1'
        $content = $content -replace "(?<!\-)[Ff]ilter\ +([_A-Za-z]+)", 'Filter global:$1'
        $content = $content -replace "[Ss][Ee][Tt]\-[Aa][Ll][Ii][Aa][Ss]\ +(.*)", 'Set-Alias -Scope Global $1'

        Write-Output $content
    }
    Function Install-DockerCompletion {
        Install-Module DockerCompletion -Scope CurrentUser -Force
    }
    Function Install-KubeCompletion {
        [CmdletBinding()]
        param([Alias("CompletionsPath")][string]$path)

        ## kubectl completion for PowerShell required v1.23.x
        $version = ConvertFrom-JSON -InputObject (kubectl version).Replace("Client Version: version.Info", "")
        if ($version.Minor -lt 23) {
            Write-Host "kubectl CLI completion requires v1.23.0 or later. Please, upgrade kubectl.exe." -ForegroundColor Red
            Write-Host "Please, refer to the following instructions to install kubectl:" -ForegroundColor Yellow
            Write-Host "   https://kubernetes.io/docs/tasks/tools/install-kubectl-windows" -ForegroundColor DarkGray
            return
        }

        New-Item -Path $path -ItemType Directory -EA SilentlyContinue | Out-Null
        kubectl completion powershell | Out-String | Set-Content -Encoding ASCII -NoNewline -Path $path/kubectl.ps1
    }
    Function Install-HelmCompletion {
        [CmdletBinding()]
        param([Alias("CompletionsPath")][string]$path)
        New-Item -Path $path -ItemType Directory -EA SilentlyContinue | Out-Null
        helm completion powershell | Out-String | Set-Content -Encoding ASCII -NoNewline -Path $path/helm.ps1
    }

    $completionsPath = Join-Path (Split-Path -Parent $PROFILE) Completions
    if (-not (Has-Module DockerCompletion)) { Install-DockerCompletion }
    if (-not (Test-Path $completionsPath/helm.ps1)) {
        Install-HelmCompletion -Completions $completionsPath
    }
    if (-not (Test-Path $completionsPath/kubectl.ps1)) {
        Install-KubeCompletion -Completions $completionsPath
    }

    Import-Module DockerCompletion

    if (Test-Path $completionsPath/helm.ps1) {
        Get-PwshExpression -Path "$completionsPath/helm.ps1" | Invoke-Expression
    }
    if (Test-Path $completionsPath/kubectl.ps1) {
        Get-PwshExpression -Path "$completionsPath/kubectl.ps1" | Invoke-Expression
    }
}

Function compose { docker compose $args }

Set-Alias -Name "kube" -Value kubectl
Set-Alias -Name "kc" -Value kubectl