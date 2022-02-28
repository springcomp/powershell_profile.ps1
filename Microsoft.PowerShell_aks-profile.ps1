"$($Env:USERPROFILE)/.azure-kubectl", `
"$($Env:USERPROFILE)/.azure-kubelogin" `
	| Add-DirectoryToPath -Prepend