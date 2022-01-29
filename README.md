# Get-LatestWindowsPatchingDate v1.1
Get the dates of 3 separate patching mechanisms to determine the 'updatedness' of all Domain Server where enterprise tools such as WSUS, SCCM and other 3rd party tools are unavailable.

# Who is This Script For?
1. System admins, server engineers who have no access to entrerprise patching reporting tools/applicaitons.
2. System Admins, server engineers who have a joing a new company with no patchings tools who need a quick solution to get an overview of windows server patching levels/dates to determine how out of date their new environment is.
3. Small local managed service provider engineers who's customers dont have access to patch management tools who need a quick solution to get an overview of windows server patching levels/dates to determine how out of date their customer is.

# What does this Script Check?
1. Most recent InstalledOn date from Get-Hotfix (see section below)
2. Most recent date from the Setup Event Log for Event ID 2 where the message contains "Installed"
3. The most recent date of critical system files such as ntoskrnl.exe, win32k.sys, KERNEL32.dll etc (8 files in total)

# But Get-Hotfix is reknowned for not returning dates on loads of hotfixes, wont that skew the results?
While investigating this script for work as a report for my team leader, I discovered that Get-Hotfix when run remotely against a server using Get-Hotfix -ComputerName <remote server> will retun InstalledOn dates for ALL patches, even when Get-Hotfix doesnt return dates when run locally on that same server.
To that end, Get-Hotfix attempts to run remotely against all server first, and then if it fails, will fall back to running locally on remote server via Invoke-Command.
  
# Execution
Download the scripts and store them locally in a folder of your choice.
Exectue the script using .\Get-Latest-WindowsPatchingDate (use ps7 for faster parallel processing, adjust your throttlelimit based on the RAM available on the machine you're running it from)
A sub folder called REPORTS will be created.
The script outputs two csv files, one for all servers and one for servers where the system file date is older than 90 days.
You can modify this second folder to suite your needs of what you want to define as 'out of date' servers.

# Notes and Observations
1. Windows Server DOES NOT log Defender defintion updates to Setup Event Log nor to Get-Hotfix
  Defender updates are ALWAYS KB2267602 and then prefixed with a version number.
  my investigation while writing this script found no instances of this KB in either Get-Hotix nor the Setup event log.
2. This script is meant for small teams who patch manually without the aid of enterprise tools so it therefore stands to reason that applications such as SQL, Exchange etc would also be patched alongside windows patching, therefore the dates provided by this script would allow a small team, who patch manually a suitable 'viewport' into their overall patching status.
  
# Thanks to the following on Reddit
u/TumsFestivalEveryDay for the Get-WinEvent code snippet which I modified to suit.
u/BigHandLittleSlap for pointing out the flaw in my original scripts 'logic' and the system files code which I modified to suit.
