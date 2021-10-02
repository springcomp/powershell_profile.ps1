Function Get-LoadedProfile {
    Get-Content -Path (Get-Profile "profiles") |% {
        $matched = $_ -match "^Load\-Profile `"(?<profile>[^`"]+)`""
        if ($matched) { $matches["profile"] }
    }
}
