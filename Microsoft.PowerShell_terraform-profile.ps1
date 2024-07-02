# 1.0.8949.21274

$Env:__TERRAFORM_HOME = "C:\Portable Apps\Terraform"
$Env:__TERRAFORM_HOME `
	| Add-DirectoryToPath

Function tf-init {
    terraform init `
        -backend-config $PWD\tfbackend.tfvars `
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

## the Terraform Version Manager
Function tvm {
	[CmdletBinding()]
	param(
		[Parameter(Position = 0)]
		[string] $action = "list",

		[Parameter(Position = 1)]
		[string] $version = $null,

		[switch] $remote
	)

	BEGIN {

		$HOME_DIR = $Env:__TERRAFORM_HOME

		Write-Host $HOME_DIR

		Function Get-TerraformVersion {
			$terraform_exe = "$HOME_DIR/terraform.exe"
			if (Test-Path $terraform_exe) {
				$output = iex ". `"$($terraform_exe)`" version" -EA SilentlyContinue
				$caption = $output | Select -First 1
				$match = $caption -match "^Terraform v(?<ver>[0-9\.]+)$"
				if ($match) { Write-Output $matches["ver"] }
			}
		}

		## -action list
		Function Get-LocalVersion {
			[CmdletBinding()]
			param(
				[switch]$trim
			)

			$currentVersion = Get-TerraformVersion

			Get-ChildItem -Path $HOME_DIR -Filter "terraform-*.exe" |% {
				$name = $_.Name
				$match = $name -match '^terraform-(?<ver>[0-9\.]+)\.exe$'
				if ($match) {
					$localVersion = $matches["ver"]
					if ($trim.IsPresent) {
						Write-Output $localVersion
					}
					else {
						if ($localVersion -eq $currentVersion) { Write-Host "* $localVersion" }
						else { Write-Output "  $localVersion" }
					}
				}
			}
		}

		## [-action] list -remote
		Function Get-RemoteVersion {

			$localVersions = Get-LocalVersion -Trim
			if (-not $localVersions) { $localVersions = @() }

			$raw = Invoke-RestMethod -Method Get -Uri "https://releases.hashicorp.com/terraform/"
			$raw -split "`n" |% {
				$line = $_
				$match = $line -match "\<a href=`"/terraform\/(?<ver>[0-9\.]+)\/`"\>"
				if ($match) {
					$remoteVersion = $matches["ver"]
					$contains = $localVersions.Contains($remoteVersion)
					if ($contains) { Write-Output "* $remoteVersion" }
					else { Write-Output "  $remoteVersion" }
				}
			}
		}

		## [-action] install -version <version>
		Function Install-Version {
			[CmdletBinding()]
			param(
				[Parameter(Mandatory = $true)]
				[string]$version
			)

			Remove-Item -Path $Env:TEMP\tf.zip -EA SilentlyContinue
			Remove-Item -Path $Env:TEMP\tf_ -Recurse -Force -EA SilentlyContinue

			$uri = "https://releases.hashicorp.com/terraform/$($version)/terraform_$($version)_windows_amd64.zip"
			Invoke-RestMethod `
				-Method GET `
				-Uri $uri `
				-Outfile $Env:TEMP\tf.zip

			Expand-Archive `
				-Path $Env:TEMP\tf.zip `
				-DestinationPath $Env:TEMP\tf_

			Copy-Item `
				-Path $Env:TEMP\tf_\terraform.exe `
				-Destination "$($HOME_DIR)\terraform-$($version).exe" `
				-Force
		}

		## [-action] uninstall -version <version>
		Function Uninstall-Version {
			[CmdletBinding()]
			param(
				[Parameter(Mandatory = $true)]
				[string]$version
			)

			$currentVersion = Get-TerraformVersion
			if ($version -eq $currentVersion) {
				Remove-Item "$HOME_DIR/terraform.exe" -EA SilentlyContinue
			}

			Remove-Item `
				-Path "$HOME_DIR/terraform-$($version).exe" `
				-EA SilentlyContinue
		}

		## [-action] select -version <version>
		Function Select-Version {
			[CmdletBinding()]
			param(
				[Parameter(Mandatory = $true)]
				[string]$version
			)

			$localVersions = Get-LocalVersion -Trim
			if ($localVersions.Contains($version)) {
				Remove-Item -Path "$HOME_DIR/terraform.exe" -EA SilentlyContinue
				Copy-Item `
					-Path "$HOME_DIR/terraform-$($version).exe" `
					-Destination "$HOME_DIR/terraform.exe" `
					-Force
			}
		}
	}
	PROCESS {

		if ($action -eq "list") {
			if ($remote.IsPresent) { Get-RemoteVersion }
			else { Get-LocalVersion }
		}

		if ($action -eq "install") { Install-Version -version $version }
		if ($action -eq "uninstall") { Uninstall-Version -version $version }
		if ($action -eq "select") { Select-Version -version $version }
	}
}