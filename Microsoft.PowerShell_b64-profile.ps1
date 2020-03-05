Function b64 {
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$inputObject
    )
    PROCESS {
        $base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($inputObject))
        Write-Output $base64
    }
}
Function ub64 {
    [cmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$inputObject
    )
    PROCESS {
        $buffer = [Convert]::FromBase64String($inputObject)
        $text = [Text.Encoding]::UTF8.GetString($buffer)
        Write-Output $text
    }
}