Clear-Host
$servers = $null
$results = $null
$3months = $null

$servers = (Get-ADComputer -Filter 'Enabled -eq $true -and OperatingSystem -like "Windows Server*"' |
		Where-Object { $_.DistinguishedName -notlike '*Servers_Old_ToBeDeleted*' -and $_.Description -notlike 'Failover cluster virtual network name account' } |
			Sort-Object -Property Name).Name



### PSv7 Parallel Execution ###
# Adjust your throttle limit to suit your CPU/RAM spec on the execution server #
$results = $servers | ForEach-Object -ThrottleLimit 20 -Parallel {
	$serverName = "$_"
	try {
		Get-HotFix -ComputerName $serverName -WarningAction Stop -ErrorAction Stop | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
	}
	catch {
		Invoke-Command -ComputerName $serverName -ScriptBlock {
			Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
		}
	}
}

### CSV OUTPUT ###
$results | Select-Object -Property PSComputerName, Description, HotFixID, InstalledOn |
	Sort-Object -Property InstalledOn -Descending |
		Export-Csv -Path 'c:\temp\latest-windows-update.csv' -NoTypeInformation


###  OPTIONAL - FILTER ONLY SERVERS THAT ARE OLDER THAN 3 MONTHS OUT OF DATE ###
$3months = $results | Where-Object { $_.InstalledOn -lt "$((Get-Date).AddDays(-90))" }

$3months | Select-Object -Property PSComputerName, Description, HotFixID, InstalledOn |
	Sort-Object -Property InstalledOn -Descending |
		Export-Csv -Path 'c:\temp\3months-windows-update.csv' -NoTypeInformation
