# Get-LatestWindowsPatchingDate
Get the dates of 3 separate patching mechanisms to determine the 'updatedness' of a single or multiple windows machines where enterprise tools such as WSUS, SCCM and other 3rd party tools are unavailable.

# ChangeLog

## v1.3
moved comment block out of function code

added check for localhost or remote machine and have different code execute for each instance
as Ciminstance and Get-Item were failing locally on testing.
## v1.2
Converted script to a function

Removed output files
## v1.1
Added additional checks for critical system files and Setup Event Log

Re-wrote entire script
## v1.0
Original Version

# Who is This Script For? 
1. System admins, server engineers who have no access to enterprise patching reporting tools/applications. 
2. System Admins, server engineers who have joined a new company with no patching tools who need a quick solution to get an overview of windows server patching levels/dates to determine how out of date their new environment is. 
3. Small local managed service provider engineers whose customers don't have access to patch management tools who need a quick solution to get an overview of windows server patching levels/dates to determine how out of date their customer is. 

# What does this Script Check? 
1. Most recent InstalledOn date from Get-Hotfix (see section below) 
2. Most recent date from the Setup Event Log for Event ID 2 where the message contains "Installed" 
3. The most recent date of critical system files such as ntoskrnl.exe, win32k.sys, KERNEL32.dll etc (8 files in total) 

# But Get-Hotfix is renowned for not returning dates on loads of hotfixes, wont that skew the results? 
While investigating this script for work as a report for my team leader, I discovered that Get-Hotfix when run remotely against a server using Get-Hotfix -ComputerName <remote server> will return InstalledOn dates for ALL patches, even when Get-Hotfix doesn't return dates when run locally on that same server. 

To that end, Get-Hotfix attempts to run remotely against all servers first, and then if it fails, it will fall back to running locally on remote server via Invoke-Command. 

# Execution 
Download the script and store it locally in a folder of your choice. 

dot source the function to load it:

**. .\Get-LatestWindowsPatchingDate.ps1**
  
Run the script against the localhost:
  
**Get-LatestWindowsPatchingDate**
  
Run the script against a remote machine:
  
**Get-LatestWindowsPatchingDate -ComputerName myServer1**

# Notes and Observations 
Windows Server DOES NOT log Defender definition updates to Setup Event Log nor to Get-Hotfix. 
  
Defender updates are ALWAYS KB2267602 and then suffixed with a version number. 
  
My investigation while writing this script found no instances of this KB in either Get-Hotix nor the Setup event log. 

This script is meant for small teams who patch manually without the aid of enterprise tools so it therefore stands to reason that applications such as SQL, Exchange etc would also be patched alongside windows patching, therefore the dates provided by this script would allow a small team, who patch manually a suitable 'viewport' into their overall patching status. 

# Thanks to the following on Reddit 

u/TumsFestivalEveryDay for the Get-WinEvent code snippet which I modified to suit. 

u/BigHandLittleSlap for pointing out the flaw in my original scripts 'logic' and the system files code which I modified to suit. 
  
u/Semicol0n for the recommendation to allow single computer query and allow user to determine output which allowed me to convert it to a function.


# Output Example 
## Localhost
![localhost](https://i.imgur.com/FJRPgcV.png) 
  
## Remote Servers
![remoteservers](https://i.imgur.com/Mqe8Fky.png)
  
## Remote Windows 10
![remotewin10](https://i.imgur.com/92aCze4.png)

 
