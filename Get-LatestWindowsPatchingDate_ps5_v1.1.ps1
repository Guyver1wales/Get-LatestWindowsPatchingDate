#requires -version 5
<#
.SYNOPSIS
	Get-LatestWindowsPatchingDate-PS5

.DESCRIPTION
	Queries Get-Hotfix, Critical SystemFiles and the Setup Event Log
	to build a cohesive picture of when all domain servers were last patched.

	Get around the main issue of Get-Hotfix not supplying install dates for patches
	by running get-hotfix remotely against servers rather than executing it locally
	as when run remotely, it always returns installedon dates.


.INPUTS
	none

.OUTPUTS
	$dir\REPORTS\latest-windows-update.csv
	$dit\REPORTS\90days-windows-update.csv

.NOTES
	Version:		1.1
	Author:			Leon Evans
	Creation Date: 	29/01/2022
	Location:		https://github.com/Guyver1wales/Get-LatestWindowsPatchingDate
	Change Log:
	v1.0
	Original Version

.EXAMPLE
	.\Get-LatestWindowsPatchingDate-PS5
#>

#* ---------------------------------------------------------
#* INITIALISATIONS
#* ---------------------------------------------------------
#*	1> define initialisations and global configurations
#*	2> list dot Source required Function Libraries
#region initialisations

### CREATE EXECUTION FOLDER $DIR VARIABLE ###
$scriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path -Path $scriptPath

## DEFINE SCRIPT PATHS ##
$scriptPaths = @()
$scriptPaths += $dir
$scriptPaths += "$dir\REPORTS"

## TEST/CREATE PATHS: ##
foreach ($_ in $scriptPaths) {
	if (-Not(Test-Path -Path "$_")) {
		New-Item -Path "$_" -ItemType Directory
	}
}

#endregion initialisations

#* ---------------------------------------------------------
#* DECLARATIONS
#* ---------------------------------------------------------
#*	3> define and declare variables here
#*	All variables to conform to the lowerCamelCase format:
#*	e.g. $scriptVersion = '1.0', $fileName = 'output.txt'
#region declarations

### SCRIPT VARIABLES ###	modify or remove as required

# NULL VARIABLES #
$servers = $null
$results = $null
$3months = $null

# DEFAULT FOLDER VARIABLES #
$reports = "$dir\REPORTS"

# DEFINE YOUR AD QUERY TO RETURN YOUR DESIRED SERVERS #
$servers = (Get-ADComputer -Properties Description -Filter 'Enabled -eq $true -and OperatingSystem -like "Windows Server*"' | Where-Object { ($_.DistinguishedName -notlike '*Servers_Old_ToBeDeleted*' -and $_.Description -notlike 'Failover cluster*') } | Sort-Object -Property Name).Name

#endregion declarations

#* ---------------------------------------------------------
#* FUNCTIONS
#* ---------------------------------------------------------
#*	4> primary functions and helpers should be abstracted here
#region functions

#endregion functions

#* ---------------------------------------------------------
#* EXECUTION
#* ---------------------------------------------------------
#*	6> execution, actions and callbacks should be placed here
#region execution

########################################
### GET DATA FROM ALL DOMAIN SERVERS ###
########################################

### PSv7 Parallel Execution ###
# Adjust your throttle limit to suit your CPU/RAM spec on the execution server #
$results = foreach ($i in $servers) {
	$serverName = $i
	$operatingSystem = (Get-CimInstance -ClassName CIM_OperatingSystem ).Caption

	### GET MOST RECENT HOTFIX DATE ###
	$hotfixResult = try {
		Get-HotFix -ComputerName $serverName -WarningAction Stop -ErrorAction Stop | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
	}
	catch {
		Invoke-Command -ComputerName $serverName -ScriptBlock {
			Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
		}
	}

	### GET MOST RECENT SETUP EVENT LOG EVENT ID 2 WITH STATE 'INSTALLED' ###
	$eventLogResult = try {
		Get-WinEvent -ComputerName $serverName -LogName Setup -ErrorAction Stop -WarningAction Stop | Where-Object { $_.Id -eq '2' -and $_.Message -match 'Installed' } | Sort-Object -Property TimeCreated -Descending | Select-Object -First 1
	}
	catch {
		Invoke-Command -ComputerName $serverName -ScriptBlock {
			Get-WinEvent -LogName Setup -ErrorAction Stop -WarningAction Stop | Where-Object { $_.Id -eq '2' -and $_.Message -match 'Installed' } | Sort-Object -Property TimeCreated -Descending | Select-Object -First 1
		}
	}

	### GET MOST RECENT DATE OF CRITICAL SYSTEM FILES ###
	$systemFilesDate = Invoke-Command -ComputerName $serverName -ScriptBlock {
	(Get-Item @(
			"${env:windir}\System32\ntoskrnl.exe",
			"${env:windir}\System32\win32k.sys",
			"${env:windir}\System32\win32kbase.sys",
			"${env:windir}\System32\win32kfull.sys",
			"${env:windir}\System32\ntdll.dll",
			"${env:windir}\System32\USER32.dll",
			"${env:windir}\System32\KERNEL32.dll",
			"${env:windir}\System32\HAL.dll"
		) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Sort-Object -Property LastWriteTimeUtc -Descending | Select-Object -First 1).LastWriteTime
	}

	### CREATE PSCUSTOMOBJECT FOR FINAL OUTPUT ###
	[PSCustomObject]@{
		ServerName          = $serverName
		OperatingSystem     = $operatingSystem
		SystemFilesDate     = $systemFilesDate
		HotFixDescription   = $hotfixResult.Description
		HotFixID            = $hotfixResult.HotFixID
		HotFixInstallDate   = $hotfixResult.InstalledOn
		EventLogInstallDate = $eventLogResult.TimeCreated
		EventLogMessage     = $eventLogResult.Message
	}

	### GET MOST RECENT CRITICAL SYSTEM FILES DATE ###
	#$systemFileResult =
}

# FINAL OUTPUT SORTED BY CRITICAL SYSTEM FILE DATE #
$finalResults = $results | Sort-Object -Property SystemFilesDate -Descending

###########################
### CREATE OUTPUT FILES ###
###########################
### CSV OUTPUT ###
# ALL SERVERS #
$finalResults | Export-Csv -Path "$reports\latest-windows-update.csv" -NoTypeInformation


# SERVERS THAT ARE OLDER THAN 3 MONTHS OUT OF DATE #
$3months = $finalResults | Where-Object { $_.SystemFilesDate -lt "$((Get-Date).AddDays(-90))" }

$3months | Export-Csv -Path "$reports\3months-windows-update.csv" -NoTypeInformation


#endregion execution
