# 1.0.8224.18523
Function Update-PoshTheme {

  $address = "https://raw.githubusercontent.com/springcomp/config-files/master/.poshthemes/oh-my-posh.json"
  $ROOT="~/.poshthemes/"

  New-Item -Path $ROOT -ItemType Directory -EA SilentlyContinue | Out-Null
  Invoke-RestMethod -Uri $address -OutFile "$($ROOT)oh-my-posh.json"

}

Function Upgrade-TerminalIcons {
  
  if (Get-Module Terminal-Icons -ListAvailable) { Update-Module Terminal-Icons -Force }
  else { Install-Module Terminal-Icons -Force }

}

# Oh My Posh should be installed using WinGet
# . winget install JanDeDobbeleer.OhMyPosh -s winget
# Use the following link for bootstrap:
# https://github.com/springcomp/my-box/blob/e3a2431e448fbf7acad2fe6969a448d00bbedf11/bootstrap/pwsh-core.ps1#L83-L88 

. oh-my-posh.exe init pwsh --config "~/.poshthemes/oh-my-posh.json" | Invoke-Expression

Import-Module -Name Terminal-Icons
