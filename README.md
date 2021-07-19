# powershell_profile.ps1

Quickly install with the following command:

```pwsh
irm https://raw.githubusercontent.com/springcomp/powershell_profile.ps1/master/Microsoft.PowerShell_profile.ps1 -OutFile $profile
```

Then open a PowerShell prompt of reload your profile.

## Customize your prompt with Oh-My-Posh

```pwsh
install-profile psreadline
install-profile oh-my-posh -reload

upgrade-ohmyposh
upgrade-terminalicons
update-poshtheme
```
