if ((Get-PSSnapin | ?{$_.Name -eq "WAPPSCmdlets"}) -eq $null)
{
	Add-PSSnapin WAPPSCmdlets -erroraction SilentlyContinue
	$SnapIn = Get-PSSnapIn WAPPSCmdlets -erroraction SilentlyContinue
	if ($SnapIn -eq $null)
	{
		Write-Error "To run this script the 'Windows Azure Platform PowerShell Cmdlets ' are required."
		Write-Error "Please download from 'http://wappowershell.codeplex.com/' and install as a PowerShell Snap-in (not as a Module)."
		Exit
	}
}

function Get-ManagementCertificate
{
	param(
			[string]$managementCertificateThumbprint = $(throw '$managementCertificateThumbprint is a required parameter')
		)

	if ((Test-Path cert:\CurrentUser\MY\$managementCertificateThumbprint) -eq $true)
	{
		$certificate = (Get-Item cert:\CurrentUser\MY\$managementCertificateThumbprint)
	}
	else
	{
		$certificate = (Get-Item cert:\LocalMachine\MY\$managementCertificateThumbprint)
	}

	return $certificate
}

function Create-AffinityGroup
{
	param( 
			[string]$subscriptionId = $(throw '$subscriptionId is a required parameter'),
			[System.Security.Cryptography.X509Certificates.X509Certificate2]$managementCertificate = $(throw '$managementCertificate is a required parameter'),
			[string]$affinityGroupName = $(throw '$affinityGroupName is a required parameter'),
			[string]$affinityGroupLabel = $(throw '$affinityGroupLabel is a required parameter'),
			[string]$affinityGroupLocation = $(throw '$affinityGroupLocation is a required parameter')
		)
	
	$affinityGroup = Get-AffinityGroups -SubscriptionId $subscriptionId -Certificate $managementCertificate | where {$_.Name -eq $affinityGroupName}
	if ($affinityGroup -eq $null)
	{
		Write-Host "Creating new Windows Azure Affinity Group with name ""$affinityGroupName"""
		New-AffinityGroup -Name $affinityGroupName -Label $affinityGroupLabel -Location $affinityGroupLocation -SubscriptionId $subscriptionId -Certificate $managementCertificate | Get-OperationStatus -WaitToComplete
		Write-Host "`n"
	}
	else
	{
		Write-Host "Windows Azure Affinity Group already exists with name ""$affinityGroupName"""
		Write-Host "`n"
	}

	return $affinityGroup
}

function Create-HostedService
{
	param( 
			[string]$subscriptionId = $(throw '$subscriptionId is a required parameter'),
			[System.Security.Cryptography.X509Certificates.X509Certificate2]$managementCertificate = $(throw '$managementCertificate is a required parameter'),
			[string]$hostedServiceName = $(throw '$hostedServiceName is a required parameter'),
			[string]$hostedServiceLabel = $(throw '$hostedServiceLabel is a required parameter'),
			[string]$affinityGroupName = $(throw '$affinityGroupName is a required parameter')
		)
	
	$hostedService = Get-HostedServices -SubscriptionId $subscriptionId -Certificate $managementCertificate | where {$_.ServiceName -eq $hostedServiceName}
	if ($hostedService -eq $null)
	{
		Write-Host "Creating new Windows Azure Hosted Service with name ""$hostedServiceName"""
		New-HostedService -ServiceName $hostedServiceName -Label $hostedServiceLabel -AffinityGroup $affinityGroupName -SubscriptionId $subscriptionId -Certificate $managementCertificate | Get-OperationStatus -WaitToComplete
		$hostedService = Get-HostedService -ServiceName $hostedServiceName -SubscriptionId $subscriptionId -Certificate $managementCertificate
		Write-Host "`n"
	}
	else
	{
		Write-Host "Windows Azure Hosted Service already exists with name ""$hostedServiceName"""
		Write-Host "`n"
	}

	return Get-HostedService -ServiceName $hostedServiceName -SubscriptionId $subscriptionId -Certificate $managementCertificate
}

function Create-StorageAccount
{
	param( 
			[string]$subscriptionId = $(throw '$subscriptionId is a required parameter'),
			[System.Security.Cryptography.X509Certificates.X509Certificate2]$managementCertificate = $(throw '$managementCertificate is a required parameter'),
			[string]$storageAccountName = $(throw '$storageAccountName is a required parameter'),
			[string]$storageAccountLabel = $(throw '$storageAccountLabel is a required parameter'),
			[string]$affinityGroupName = $(throw '$affinityGroupName is a required parameter')
		)
	
	$storageAccount = Get-StorageAccount -SubscriptionId $subscriptionId -Certificate $managementCertificate | where {$_.ServiceName -eq $storageAccountName}
	if ($storageAccount -eq $null)
	{
		Write-Host "Creating new Windows Azure Storage Account with name ""$storageAccountName"""
		New-StorageAccount -ServiceName $storageAccountName -Label $storageAccountLabel -AffinityGroup $affinityGroupName -SubscriptionId $subscriptionId -Certificate $managementCertificate | Get-OperationStatus -WaitToComplete
		Write-Host "`n"
	}
	else
	{
		Write-Host "Windows Azure Storage Account already exists with name ""$storageAccountName"""
		Write-Host "`n"
	}

	return $storageAccount
}

function Delete-StagingEnvironment
{
	param(
			[Microsoft.WindowsAzure.Samples.ManagementTools.PowerShell.Services.Model.HostedServiceContext]$hostedService = $(throw '$hostedService is a required parameter')
		)

	if (($hostedService | Get-Deployment Staging).DeploymentId -ne $null)
	{
		Write-Host "Suspending legacy Staging Environment Deployment (required to accomodate new Deployment)"
		$hostedService | Get-Deployment -Slot Staging | Set-DeploymentStatus Suspended | Get-OperationStatus -WaitToComplete
		Write-Host "`n"

		Write-Host "Deleting legacy Staging Environment Deployment (required to accomodate new Deployment)"
		$hostedService | Get-Deployment -Slot Staging | Remove-Deployment | Get-OperationStatus -WaitToComplete
		Write-Host "`n"
	}
	else
	{
		Write-Host "No existing Staging Environment Deployment"
		Write-Host "`n"
	}
}

function Create-Deployment
{
	param(
			[Microsoft.WindowsAzure.Samples.ManagementTools.PowerShell.Services.Model.HostedServiceContext]$hostedService = $(throw '$hostedService is a required parameter'),
			[string]$packageFilePath = $(throw '$packageFilePath is a required parameter'),
			[string]$configurationFilePath = $(throw '$configurationFilePath is a required parameter'),
			[string]$deploymentLabel = $(throw '$deploymentLabel is a required parameter'),
			[string]$storageAccountName = $(throw '$storageAccountName is a required parameter'),
			[bool]$promoteToProductionEnvironment = $(throw '$promoteToProductionEnvironment is a required parameter'),
			[bool]$removeStagingEnvironmentAfterwards = $(throw '$removeStagingEnvironmentAfterwards is a required parameter')
		)

	Write-Host "Creating a Deployment to Staging Environment using Package from ""$packageFilePath"" and Configuration from ""$configurationFilePath"" with label ""$deploymentLabel"""
	$hostedService | New-Deployment -Slot Staging -StorageServiceName $storageAccountName -Package $packageFilePath -Configuration $configurationFilePath -Label $deploymentLabel | Get-OperationStatus -WaitToComplete
	Write-Host "`n"

	Write-Host "Starting the Deployment on Staging Environment"
	$hostedService | Get-Deployment -Slot Staging | Set-DeploymentStatus -Status Running | Get-OperationStatus -WaitToComplete
	Write-Host "`n"

	if ($promoteToProductionEnvironment)
	{
		Write-Host "VIP swapping the Deployment from Staging Environment to Production Environment (""PromoteToProductionEnvironment"" specified as true)"
		$hostedService | Get-Deployment -Slot Staging | Move-Deployment | Get-OperationStatus -WaitToComplete
		Write-Host "`n"
	}

	if ($promoteToProductionEnvironment -and $removeStagingEnvironmentAfterwards)
	{
		$deployment = $hostedService | Get-Deployment -Slot Staging
		if ($deployment.DeploymentId -eq $null)
		{
			Write-Host "Skipping suspending and deleting Staging Environment Deployment (""PromoteToProductionEnvironment"" specified as true and ""RemoveStagingEnvironmentAfterwards"" specified as true) as no Staging Environment Deployment existed"
			Write-Host "`n"
		}
		else
		{
			Write-Host "Suspending Staging Environment Deployment (""PromoteToProductionEnvironment"" specified as true and ""RemoveStagingEnvironmentAfterwards"" specified as true)"
			$deployment | Set-DeploymentStatus Suspended | Get-OperationStatus -WaitToComplete
			Write-Host "`n"
			Write-Host "Deleting Staging Environment Deployment (""PromoteToProductionEnvironment"" specified as true and ""RemoveStagingEnvironmentAfterwards"" specified as true)"
			$deployment | Remove-Deployment | Get-OperationStatus -WaitToComplete
			Write-Host "`n"
		}
	}
}
