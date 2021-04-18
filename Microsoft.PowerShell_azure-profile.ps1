## disable AZ CLI cert validation to prevent
## failures that occur behind some corporate firewalls
## 
$Env:AZURE_CLI_DISABLE_CONNECTION_VERIFICATION = "1"
$Env:ADA_PYTHON_SSL_NO_VERIFY = "1"

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

#Begin Azure PowerShell alias import
Import-Module Az.Accounts -ErrorAction SilentlyContinue -ErrorVariable importError
if ($importerror.Count -eq 0) { 
    Write-Host "Enable-AzureRmAlias" -ForegroundColor DarkGray
    Enable-AzureRmAlias -Module `
            Az.Accounts, `
            Az.Aks, `
            Az.AnalysisServices, `
            Az.ApiManagement, `
            Az.ApplicationInsights, `
            Az.Automation, `
            Az.Backup, `
            Az.Batch, `
            Az.Billing, `
            Az.Cdn, `
            Az.CognitiveServices, `
            Az.Compute, `
            Az.Compute.ManagedService, `
            Az.ContainerInstance, `
            Az.ContainerRegistry, `
            Az.DataFactory, `
            Az.DataLakeAnalytics, `
            Az.DataLakeStore, `
            Az.DataMigration, `
            Az.DeviceProvisioningServices, `
            Az.DevSpaces, `
            Az.Dns, `
            Az.EventGrid, `
            Az.EventHub, `
            Az.FrontDoor, `
            Az.HDInsight, `
            Az.IotCentral, `
            Az.IotHub, `
            Az.KeyVault, `
            Az.LogicApp, `
            Az.MachineLearning, `
            Az.ManagedServiceIdentity, `
            Az.ManagementPartner, `
            Az.Maps, `
            Az.MarketplaceOrdering, `
            Az.Media, `
            Az.Monitor, `
            Az.Network, `
            Az.NotificationHubs, `
            Az.OperationalInsights, `
            Az.PolicyInsights, `
            Az.PowerBIEmbedded, `
            Az.RecoveryServices, `
            Az.RedisCache, `
            Az.Relay, `
            Az.Reservations, `
            Az.ResourceGraph, `
            Az.Resources, `
            Az.Scheduler, `
            Az.Search, `
            Az.Security, `
            Az.ServiceBus, `
            Az.ServiceFabric, `
            Az.SignalR, `
            Az.Sql, `
            Az.Storage, `
            Az.StorageSync, `
            Az.StreamAnalytics, `
            Az.Subscription, `
            Az.TrafficManager, `
            Az.Websites `
        -ErrorAction SilentlyContinue `
        ; 
}
#End Azure PowerShell alias import