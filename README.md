# Get-LatestWindowsPatchingDate
Get the date of the most recently installed windows Update patch for all domain servers

This script attempts, very simply, to overcome the most common frustrations of using Get-Hotfix or Get-WMIObject -Class Win32_quickfixengineering which is the lack of dates supplied by the 'InstalledOn' object property.

While attempting to write an automation report for my team lead in work for this very 'simple' thing I kept hitting two road blocks:
1. no dates in a lot of returned hotfixes meaning that when sorting by InstalledOn, my report would end up reporting the most recent patch that had a date in this property, unfortuately this was often months or even sometimes years out of date leading to innaccurate reporting.
2.  when using Get-Hotfix -ComputerName <remote server name>, the command fails with get-hotfix : No such interface supported, even though remote powershell works to these remote servers and you normally experience no issues getting information via remote powershell from these servers.

### Note
Things I have noted while writing this script:

Get-Hotfix -ComputerName <remote server name> will return 'InstalledOn' dates for ALL patches when Get-Hotfix is run locally on the same machine and does not return dates for all patches.
  
# Execution
I have provided two version, on for serial execution using PowerShell v5 and one for Parallel execution using PowerShell v7

The script gets all your domain server based on the $servers variable query (feel free to modify this to your needs/environment).
The script then attempts to connect to each server remotely using **Get-Hotfix -ComputerName <remote server name>** and sort the results by InstalledOn and return only the latest patch date.
If this fails then it will instead attempt to fall back and try using Invoke-Command and execute Get-Hotfix on the remote server locally, again sorting by InstalledOn and returning only the latest patch date.
  
It will then output the date sorted list to a csv to a folder on your chosing using the $outputFolder variable.
  
I have also included a second filtering option so you can filter a separate csv for a specific time range (default is 90 days) so you can get a separate list of servers that have not been patched for x days if you so desire such a thing for a compliance/maanger report.
  
Using Get-Hotfix -ComputerName and then falling back to Invoke-Command gave me a 100% return rate across 270 domain servers with 100% accurate latest patching date.
