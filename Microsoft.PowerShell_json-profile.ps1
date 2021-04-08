Function Load-Json {
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [string] $path
    )

    $lines = [String]::Join("`r`n", (Get-Content -Path $path -Raw))
    $json = ConvertFrom-Json -InputObject $lines
    Write-Output $json
}

Set-Alias -Name json -Value Load-Json

Function isjson {
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("PSPath")]
        [string] $path
    )
    try {
        $json = Load-Json -Path $path
        return $true
    }
    catch 
    {
        Write-Host "NOPE"

    }
}