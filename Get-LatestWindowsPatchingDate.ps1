function Get-LatestWindowsPatchingDate {
	<#
		 .SYNOPSIS
			Get-LatestWindowsPatchingDate

		.DESCRIPTION
			Queries Get-Hotfix, Critical SystemFiles and the Setup Event Log
			to build a cohesive picture of when all domain servers were last patched.

			Get around the main issue of Get-Hotfix not supplying install dates for patches
			by running get-hotfix remotely against servers rather than executing it locally
			as when run remotely, it always returns installedon dates.

		.EXAMPLE
			. .\Get-LatestWindowsPatchingDate.ps1

			Example 1 - localhost
			Get-LatestWindowsPatchingDate

			Example 2 - remote server
			Get-LatestWindowsPatchingDate -ComputerName <server name>

		.INPUTS
			alphanumeric for -ComputerName

		.OUTPUTS
			console output to host

		.NOTES
			Version:		1.2
		Author:			Leon Evans
		Creation Date: 	29/01/2022
		Location:		https://github.com/Guyver1wales/Get-LatestWindowsPatchingDate
		Change Log:
		v1.2
			Converted script to a function
		v1.1
			Added additional checks for critical system files and Setup Event Log
			Re-wrote entire sctipt
		v1.0
			Original Version
	#>


	[OutputType([array])]
	Param
	(
		# SPECIFY COMPUTER NAME. DEFAULTS TO LOCAL HOSTS COMPUTERNAME #
		[Parameter(
			ValueFromPipelineByPropertyName = $true,
			Position = 0,
			HelpMessage = 'Input the Hostname of the computer you want to query')]
		[ValidatePattern('[A-Za-z0-9]')]
		[string]$ComputerName = $env:COMPUTERNAME
	)

	Begin {
		# NULL VARIABLES #
		$servers = $null
		$results = $null
		$3months = $null
	}
	Process {
		$operatingSystem = (Get-CimInstance -ComputerName $ComputerName -ClassName CIM_OperatingSystem ).Caption

		### GET MOST RECENT HOTFIX DATE ###
		$hotfixResult = try {
			Get-HotFix -ComputerName $ComputerName -WarningAction Stop -ErrorAction Stop | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
		}
		catch {
			Invoke-Command -ComputerName $ComputerName -ScriptBlock {
				Get-HotFix | Sort-Object -Property InstalledOn -Descending | Select-Object -First 1
			}
		}

		### GET MOST RECENT SETUP EVENT LOG EVENT ID 2 WITH STATE 'INSTALLED' ###
		$eventLogResult = try {
			Get-WinEvent -ComputerName $ComputerName -LogName Setup -ErrorAction Stop -WarningAction Stop | Where-Object { $_.Id -eq '2' -and $_.Message -match 'Installed' } | Sort-Object -Property TimeCreated -Descending | Select-Object -First 1
		}
		catch {
			Invoke-Command -ComputerName $ComputerName -ScriptBlock {
				Get-WinEvent -LogName Setup -ErrorAction Stop -WarningAction Stop | Where-Object { $_.Id -eq '2' -and $_.Message -match 'Installed' } | Sort-Object -Property TimeCreated -Descending | Select-Object -First 1
			}
		}

		### GET MOST RECENT DATE OF CRITICAL SYSTEM FILES ###
		$systemFilesDate = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
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
	}
	End {
		### CREATE PSCUSTOMOBJECT FOR FINAL OUTPUT ###
		[PSCustomObject]@{
			ServerName          = $ComputerName
			OperatingSystem     = $operatingSystem
			SystemFilesDate     = $systemFilesDate
			HotFixDescription   = $hotfixResult.Description
			HotFixID            = $hotfixResult.HotFixID
			HotFixInstallDate   = $hotfixResult.InstalledOn
			EventLogInstallDate = $eventLogResult.TimeCreated
			EventLogMessage     = $eventLogResult.Message
		}
	}
}