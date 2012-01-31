function Check-Prerequisites
{
	param(
			[bool]$azurePublishActionRequired = $(throw '$azurePublishActionRequired is a required parameter')
		)

	if ($azurePublishActionRequired)
	{
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
	}
}