Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -PredictionSource History

$promptChar = [char]0xe0b0
$options = @{
    PromptText = `
        "`e[38;2;88;88;88m${promptChar}`e[0m ", `
        "`e[91m${promptChar}`e[0m " `
        ;
}
Set-PSReadLineOption @options
Set-PSReadLineOption -ContinuationPrompt "`e[48;2;88;88;88m `e[0m`e[38;2;88;88;88m$([char]0xE0B0)`e[0m "

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -ViMode Insert -Chord "Ctrl+)" -Function AcceptNextSuggestionWord

## As a matter of habit, remap $ and _ keys from French AZERTY layout
## to the new keys from the French AZERTY-NF layout

Set-PSReadLineKeyHandler -Key '+' -ViMode Command -Function MoveToEndOfLine
Set-PSReadLineKeyHandler -Key "’" -ViMode Command -Function GotoFirstNonBlankOfLine
