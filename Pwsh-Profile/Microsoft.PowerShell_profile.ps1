Function Set-LastUpdatedProfile {
    [CmdletBinding()]
    param( [string]$name = "", [DateTime]$dateTime = [DateTime]::UtcNow )
    
    $cachedProfileUpdateFile = Get-CachedProfileUpdatePath -Name $name
    $timestamp = $dateTime.ToString("yyyy-MM-ddTHH:mm:ss.fffffffZ")
    
    Set-Content `
        -Path $cachedProfileUpdateFile `
        -Value $timestamp
}

# Windows PowerShell (5.x) has conflicting alias "lp" for "Out-Printer"
if ([bool] (Get-Alias -Name lp -EA SilentlyContinue |? { $_.ResolvedCommand.Name -eq "Out-Printer"  })) {
    Remove-Item -Path "alias:\lp"
}
