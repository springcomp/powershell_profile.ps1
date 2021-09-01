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

## How does it work?

PowerShell runs a default `$profile` script upon starting a new session.

This repository contains a default `Microsoft.PowerShell_profile.ps1` profile that contains useful functions to help setting up extensible customizations at will. This script is hardcoded and should never be modified manually by the user. Instead, this script delegates to a secondary script `Microsof.PowerShell_profiles-profile.ps1` that loads other profiles as necessary.

Each additional 'profile' script must adhere to the naming convention: `Microsoft.PowerShell_<profile-name>-profile.ps1` where `<profile-name>` is in lower case.

When running a new session, PowerShell runs the default `Microsoft.PowerShell_profile.ps1` script. This loads the useful profile functions in the current session. Since the last line of the script is `Load-Profile "profiles" -Quiet`, it also attempts to find the `Microsoft.PowerShell_profiles-profile.ps1` script and run it.

In this secondary script, there is a list of all the additional "profiles" that you want to run:

```pwsh
Load-Profile "oh-my-posh"
Load-Profile "psreadline"
…
```

For each of those additional profiles, if the corresponding script exists it will be run. This allows to group useful customizations in their own script.

Loading a profile actually executes the Powershell commands found in the corresponding script using the `Invoke-Expression` CmdLet. Before that happens, however, the script needs to prepare the commands so that functions and aliases are imported into the global scope (aka, the current session).

Because this takes a bit of time, a cached version of the resulting commands is stored in the `$Env:TEMP\PowerShell_profiles` folder. Those are the scripts that are actually run every time you open a new PowerShell session.

Because I sometimes update the default profile or any other additional profile script, a _check for update_ mechanism has been built into the loading. Each additional profile may optionally contain a first line comment containing a version number. When loading a profile, the version number is checked against that of the corresponding script on this GitHub repository. If updated is needed, a warning is displayed to the user so that he or she can run a command to update the script.

## Profiles Cmdlet

The default `Microsoft.PowerShell_profile.ps1` script imports the following Cmdlets into the current session:

|Script|Description|
|---|---|
|`Add-DirectoryToPath`|Adds a directory to the `$Env:PATH` variable.|
|`CheckFor-ProfileUpdate`|Checks the version numbers from the specified local profile and its corresponding remote profile script.|
|`Download-Profile`|Download the corresponding specified remote profile script locally.|
|`Get-CachedPowerShellProfileFolder`|Returns the `$Env:TEMP\PowerShell_profiles` folder path.|
|`Get-CachedProfile`|Returns the path to the cached version of the specified profile if it exists.|
|`Get-CachedProfilePath`|Returns the path to the cached version of the specified profile. The corresponding profile may not exist.|
|`Get-Profile`|Returns the path to the specified profile if it exists.|
|`Get-ProfilePath`|Returns the path to the specified profile. The corresponding profile may not exist.|
|`Get-ProfileVersion`|Returns the profile version number. Use `-remote` to return the version number of the corresponding remote script in this GitHub repository.|
|`Install-Profile`|Downloads the specified profile and registers its loading in the `Microsoft.PowerShell_profiles-profile.ps1` script.|
|`Load-Profile`|Loads a named profile. See `Microsof.PowerShell_profiles-profile.ps1`.|
|`Update-Profile`|Replaces the specified local profile by the content from the corresponding remote profile script.|