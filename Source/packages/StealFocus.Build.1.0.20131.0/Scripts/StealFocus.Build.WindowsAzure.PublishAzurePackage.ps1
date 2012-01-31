param
(
	[string]$currentDirectory = $(throw '$currentDirectory is a required parameter'),
	[string]$subscriptionId = $(throw "subscriptionId is required"),
	[string]$managementCertificateThumbprint = $(throw "managementCertificateThumbprint is required"),
	[string]$affinityGroupName = $(throw "affinityGroupName is required"),
	[string]$hostedServiceName = $(throw "hostedServiceName is required"),
	[string]$hostedServiceLabel = $(throw "hostedServiceLabel is required"),
	[string]$storageAccountName = $(throw "storageAccountName is required"),
	[string]$packageFilePath = $(throw "packageFilePath is required"),
	[string]$configurationFilePath = $(throw "configurationFilePath is required"),
	[string]$deploymentLabel = $(throw "deploymentLabel is required"),
	[string]$removeStagingEnvironmentAfterwards = $(throw "removeStagingEnvironmentAfterwards is required"),
	[string]$promoteToProductionEnvironment = $(throw "promoteToProductionEnvironment is required")
)

[bool]$removeStagingEnvironmentAfterwardsValue = [System.Convert]::ToBoolean($removeStagingEnvironmentAfterwards)
[bool]$promoteToProductionEnvironmentValue = [System.Convert]::ToBoolean($promoteToProductionEnvironment)

Import-Module $currentDirectory\StealFocus.Build.WindowsAzure.psm1 -DisableNameChecking

$managementCertificate = Get-ManagementCertificate -managementCertificateThumbprint $managementCertificateThumbprint
$affinityGroup = Get-AffinityGroup -Name $affinityGroupName -SubscriptionId $subscriptionId -Certificate $managementCertificate
$hostedService = Create-HostedService -subscriptionId $subscriptionId -managementCertificate $managementCertificate -hostedServiceName $hostedServiceName -hostedServiceLabel $hostedServiceLabel -affinityGroupName $affinityGroupName
$storageAccount = Get-StorageAccount -SubscriptionId $subscriptionId -Certificate $managementCertificate | where { $_.ServiceName -eq $storageAccountName }
Delete-StagingEnvironment -hostedService $hostedService
Create-Deployment -hostedService $hostedService -packageFilePath $packageFilePath -configurationFilePath $configurationFilePath -deploymentLabel $deploymentLabel -storageAccountName $storageAccountName -promoteToProductionEnvironment $promoteToProductionEnvironmentValue -removeStagingEnvironmentAfterwards $removeStagingEnvironmentAfterwardsValue