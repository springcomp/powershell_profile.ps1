# 1.0.8053.38379

Set-PSReadLineOption -EditMode Vi

$psReadLineVersion = [int]"$((Get-Module PSReadLine).Version.ToString())".Replace(".", "")
if ($psReadLineVersion -ge 210) {
    $promptChar = [char]0xe0b0
    $options = @{
        PromptText = `
            "`e[38;2;88;88;88m${promptChar}`e[0m ", `
            "`e[91m${promptChar}`e[0m " `
            ;
    }
    Set-PSReadLineOption @options
    Set-PSReadLineOption -ContinuationPrompt "`e[48;2;88;88;88m `e[0m`e[38;2;88;88;88m$([char]0xE0B0)`e[0m "

    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -ViMode Insert -Chord "Ctrl+)" -Function AcceptNextSuggestionWord

    $HandleViModeChanged = [scriptblock] {
        if ($args[0] -eq 'Command') {
            # Set the cursor to a blinking block.
            Write-Host -NoNewLine "`e[1 q"
        }
        else {
            # Set the cursor to a blinking line.
            Write-Host -NoNewLine "`e[5 q"
        }
    }

    Set-PSReadLineOption -ViModeIndicator Script -ViModeChangeHandler $HandleViModeChanged
}

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

Set-PSReadLineKeyHandler -Chord "Ctrl+r" -ViMode Insert -Function ReverseSearchHistory
Set-PSReadLineKeyHandler -Chord "Ctrl+s" -ViMode Insert -Function ForwardSearchHistory

## As a matter of habit, remap $ and _ keys from French AZERTY layout
## to the new keys from the French AZERTY-NF layout

Set-PSReadLineKeyHandler -Key '+' -ViMode Command -Function MoveToEndOfLine
Set-PSReadLineKeyHandler -Key "’" -ViMode Command -Function GotoFirstNonBlankOfLine
