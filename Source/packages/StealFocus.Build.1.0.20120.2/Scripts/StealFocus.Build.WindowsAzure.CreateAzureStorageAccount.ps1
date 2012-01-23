param
(
	[string]$currentDirectory = $(throw "currentDirectory is a required parameter"),
	[string]$subscriptionId = $(throw "subscriptionId is a required parameter"),
	[string]$managementCertificateThumbprint = $(throw "managementCertificateThumbprint is a required parameter"),
	[string]$affinityGroupName = $(throw "affinityGroupName is a required parameter"),
	[string]$storageAccountName = $(throw "storageAccountName is a required parameter"),
	[string]$storageAccountLabel = $(throw "storageAccountLabel is a required parameter")
)

Import-Module $currentDirectory\StealFocus.Build.WindowsAzure.psm1 -DisableNameChecking

$managementCertificate = Get-ManagementCertificate -managementCertificateThumbprint $managementCertificateThumbprint
Create-StorageAccount -subscriptionId $subscriptionId -managementCertificate $managementCertificate -storageAccountName $storageAccountName -storageAccountLabel $storageAccountLabel -affinityGroupName $affinityGroupName
