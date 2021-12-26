# 1.0.8007.19673

"C:\Portable Apps\Terraform" `
	| Add-DirectoryToPath

Function tf-init {
    terraform init `
        -backend-config $PWD\tfbackend.tfvars
        $args
}
Function tf-plan {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform plan `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        $args
}
Function tf-apply {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform apply `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        -auto-approve `
        $args
}

Function tf-import {
    $varFile = Get-ChildItem -Path $PWD -Filter *.tfvars |? { $_.Name -ne "tfbackend.tfvars" }
    terraform import `
        -var-file "$PWD\$($varfile.Name)" `
        -var validate_datadog=false `
        $args
}