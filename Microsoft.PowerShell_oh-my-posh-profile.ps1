Add-DirectoryToPath -Path "C:\Portable Apps\oh-my-posh"

Set-Variable -Scope Global -Name Prompt -Value ([ScriptBlock] {
    $POSH_COMMAND = Get-Command -Name "oh-my-posh"
    $POSH_THEMES_FOLDER = Join-Path -Path (Split-Path -Parent $POSH_COMMAND.Source) -ChildPath ".poshthemes"
    $POSH_THEME = Join-Path -Path $POSH_THEMES_FOLDER -ChildPath "oh-my-posh.json"

    $realLASTEXITCODE = $global:LASTEXITCODE
    if ($realLASTEXITCODE -isnot [int]) {
      $realLASTEXITCODE = 0
    }
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $POSH_COMMAND
    $cleanPWD = $PWD.ProviderPath.TrimEnd("\")
    $startInfo.Arguments = " -config=`"$POSH_THEME`" -error=$realLASTEXITCODE -pwd=`"$cleanPWD`" "
    $startInfo.Environment["TERM"] = "xterm-256color"
    $startInfo.CreateNoWindow = $true
    $startInfo.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $startInfo.RedirectStandardOutput = $true
    $startInfo.UseShellExecute = $false
    if ($PWD.Provider.Name -eq 'FileSystem') {
      $startInfo.WorkingDirectory = $PWD.ProviderPath
    }
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $startInfo
    $process.Start() | Out-Null
    $standardOut = $process.StandardOutput.ReadToEnd()
    $process.WaitForExit()
    $standardOut
    $global:LASTEXITCODE = $realLASTEXITCODE
    Remove-Variable realLASTEXITCODE -Confirm:$false
})

Set-Item -Path Function:prompt -Value $prompt -Force