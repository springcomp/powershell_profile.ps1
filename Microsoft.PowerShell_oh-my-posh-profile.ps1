Function Update-PoshTheme {

  $address = "https://raw.githubusercontent.com/springcomp/config-files/master/.poshthemes/oh-my-posh.json"
  $ROOT="~/.poshthemes/"

  New-Item -Path $ROOT -ItemType Directory -EA SilentlyContinue | Out-Null
  Invoke-RestMethod -Uri $address -OutFile "$($ROOT)oh-my-posh.json"

}

Function Upgrade-OhMyPosh {
  
  if (Get-Module "oh-my-posh" -ListAvailable) { Update-Module "oh-my-posh" -Force }
  else { Install-Module "oh-my-posh" -Scope CurrentUser -Force }

}

Function Upgrade-TerminalIcons {
  
  if (Get-Module Terminal-Icons -ListAvailable) { Update-Module Terminal-Icons -Force }
  else { Install-Module Terminal-Icons -Scope CurrentUser -Force }

}

if (Get-Module "oh-my-posh" -ListAvailable) {
  Import-Module -Name "oh-my-posh"
  Set-PoshPrompt -Theme  "~/.poshthemes/oh-my-posh.json"
}

if (Get-Module Terminal-Icons -ListAvailable) {
  Import-Module -Name Terminal-Icons
}
