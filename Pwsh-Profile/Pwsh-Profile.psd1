@{
    RootModule = 'Load-Profile.psm1'
    ModuleVersion = '1.0.7947'
    GUID = '3b9dc291-4855-4402-8721-ff45cacd0a10'
    Author = 'SpringComp'
    Description = 'Manage extensible PowerShell profiles using simple CmdLets'
    PowerShellVersion = '5.0'
    NestedModules = @(
        "CheckFor-ProfileUpdate.psm1",
        "Download-Profile.psm1",
        "Get-CachedPowerShellProfileFolder.psm1",
        "Get-CachedProfile.psm1",
        "Get-CachedProfilePath.psm1",
        "Get-CachedProfileUpdatePath.psm1",
        "Get-LoadedProfile.psm1",
        "Get-Profile.psm1",
        "Get-ProfilePath.psm1",
        "Get-ProfileVersion.psm1",
        "Install-Profile.psm1",
        "Update-Profile.psm1"
    )

    ScriptsToProcess = @(
        "Microsoft.PowerShell_profile.ps1"
    )

    FunctionsToExport = @(
        "CheckFor-ProfileUpdate",
        "Download-Profile",
        "Get-CachedPowerShellProfileFolder",
        "Get-CachedProfile",
        "Get-CachedProfilePath",
        "Get-CachedProfileUpdatePath",
        "Get-LoadedProfile",
        "Get-Profile",
        "Get-ProfilePath",
        "Get-ProfileVersion",
        "Install-Profile",
        "Load-Profile",
        "Update-Profile"
    )

    CmdletsToExport = @(
    )

    VariablesToExport = '*'
    AliasesToExport = @(
        "lp", "up"
    )

    FileList = @(
        "CheckFor-ProfileUpdate.psm1",
        "Download-Profile.psm1",
        "Get-CachedPowerShellProfileFolder.psm1",
        "Get-CachedProfile.psm1",
        "Get-CachedProfilePath.psm1",
        "Get-CachedProfileUpdatePath.psm1",
        "Get-LoadedProfile.psm1",
        "Get-Profile.psm1",
        "Get-ProfilePath.psm1",
        "Get-ProfileVersion.psm1",
        "Install-Profile.psm1",
        "Load-Profile.psm1",
        "Update-Profile.psm1",

        "Microsoft.PowerShell_profile.ps1",
        "Pwsh-Profile.psd1"
    )

    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/springcomp/powershell_profile.ps1'
            RequireLicenseAcceptance = $false
        }
    }
}
