Function Get-AzCurrentSubscription {
    $context = Get-AzContext
    $name = $context.Name
    $matched = $name -match "^.*\((?<guid>[^\)]+)\).*$"
    if ($matched) {
        return $matches["guid"]
    }
}

Set-Alias -Name Get-CurrentAzSubscription -Value Get-AzCurrentSubscription
Set-Alias -Name azaccount -Value Get-AzCurrentSubscription