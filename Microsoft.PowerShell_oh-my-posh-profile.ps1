# 1.0.8398.17892

Function Update-PoshTheme {

  $address = "https://raw.githubusercontent.com/springcomp/config-files/master/.poshthemes/oh-my-posh.json"
  $ROOT="~/.poshthemes/"

  New-Item -Path $ROOT -ItemType Directory -EA SilentlyContinue | Out-Null
  Invoke-RestMethod -Uri $address -OutFile "$($ROOT)oh-my-posh.json"

}

Function Upgrade-TerminalIcons {
  
  if ($PSVersionTable.Platform -ne "Win32NT") { return }

  if (Get-Module Terminal-Icons -ListAvailable) { Update-Module Terminal-Icons -Force }
  else { Install-Module Terminal-Icons -Force }

}

# Oh My Posh should be installed using WinGet on Windows
# . winget install JanDeDobbeleer.OhMyPosh -s winget
# Use the following link for bootstrap:
# https://github.com/springcomp/my-box/blob/e3a2431e448fbf7acad2fe6969a448d00bbedf11/bootstrap/pwsh-core.ps1#L83-L88 

# Oh My Posh should be installed using Homebrew or manually on Linux
# See instructions at:
# https://ohmyposh.dev/docs/installation/linux

. oh-my-posh init pwsh --config "~/.poshthemes/oh-my-posh.json" | Invoke-Expression

if ($PSVersionTable.Platform -eq "Win32NT") {
  Import-Module -Name Terminal-Icons
}
