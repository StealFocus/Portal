param
(
	[string]$currentDirectory = $(throw "currentDirectory is a required parameter"),
	[string]$subscriptionId = $(throw "subscriptionId is a required parameter"),
	[string]$managementCertificateThumbprint = $(throw "managementCertificateThumbprint is a required parameter"),
	[string]$affinityGroupName = $(throw "affinityGroupName is a required parameter"),
	[string]$affinityGroupLabel = $(throw "affinityGroupLabel is a required parameter"),
	[string]$affinityGroupLocation = $(throw "affinityGroupLocation is a required parameter")
)

Import-Module $currentDirectory\StealFocus.Build.WindowsAzure.psm1 -DisableNameChecking

$managementCertificate = Get-ManagementCertificate -managementCertificateThumbprint $managementCertificateThumbprint
Create-AffinityGroup -subscriptionId $subscriptionId -managementCertificate $managementCertificate -affinityGroupName $affinityGroupName -affinityGroupLabel $affinityGroupLabel -affinityGroupLocation $affinityGroupLocation
