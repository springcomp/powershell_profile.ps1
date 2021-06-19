
Invoke-Expression `
  -Command (
    & "C:\Portable Apps\oh-my-posh\oh-my-posh.exe" `
      --init `
      --shell pwsh `
      --config "C:\Portable Apps\oh-my-posh\.poshthemes\oh-my-posh.json"
    )

Import-Module -Name Terminal-Icons