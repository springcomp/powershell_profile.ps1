Function text {
    "`"This is a text`nthat contains multiple lines for tests purposes.`n It also includes spaces at`n the beginning of lines`n to illustrate common pattern.`"" | clipp
}
Function p { Set-Location "c:\Projects\springcomp\PSReadLine\PSReadLine" }
Function reg {
    $Env:PSModulePath = "$($Env:PSModulePath);C:\Projects\springcomp\PSReadLine\PSReadLine\bin\Debug"
    Import-Module PSReadLine3
    Remove-Module PSReadLine
    Set-PSReadLine3Option -EditMode Vi
    Set-PSReadLine3Option -ContinuationPrompt "`e[48;2;88;88;88m `e[0m`e[38;2;88;88;88m$([char]0xE0B0)`e[0m "
    Set-PSReadLine3Option -PredictionSource History
    Set-PSReadLine3KeyHandler -Key '+' -ViMode Command -Function MoveToEndOfLine
    Set-PSReadLine3KeyHandler -Key "’" -ViMode Command -Function GotoFirstNonBlankOfLine
}

Function pwin {
    Set-PSReadLine3Option -EditMode Windows
    Set-PSReadLine3Option -ContinuationPrompt "`e[48;2;88;88;88m `e[0m`e[38;2;88;88;88m$([char]0xE0B0)`e[0m "
    Set-PSReadLine3Option -PredictionSource History
    Set-PSReadLine3KeyHandler -Chord Alt+f AcceptNextSuggestionWord
    Set-PSReadLine3KeyHandler -Chord Alt+g AcceptSuggestion
}

function apim {
    start "$Env:USERPROFILE\Professional\CHANEL IPaaS Platform - Documentation\Starter kits\Technical Design\API Management\apim-snow.ahk"
}