# Get-LatestWindowsPatchingDate v1.2
Get the dates of 3 separate patching mechanisms to determine the 'updatedness' of a single or multiple windows machines where enterprise tools such as WSUS, SCCM and other 3rd party tools are unavailable.

**Script converted to a function for v1.2 to allow single machine query and to remove output files and allow script user to determine their own output**

# Who is This Script For? 
1. System admins, server engineers who have no access to entrerprise patching reporting tools/applications. 
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
Download the scripts and store them locally in a folder of your choice. 

dot source the function to load it:

**. .\Get-LatestWindowsPatchingDate.ps1**
  
Run the script against the localhost:
  
**Get-Get-LatestWindowsPatchingDate**
  
Run the script against a remote machine:
  
**Get-LatestWindowsPatchingDate -ComputerName <remote hostname>**

# Notes and Observations 
Windows Server DOES NOT log Defender definition updates to Setup Event Log nor to Get-Hotfix. 
  
Defender updates are ALWAYS KB2267602 and then suffixed with a version number. 
  
My investigation while writing this script found no instances of this KB in either Get-Hotix nor the Setup event log. 

This script is meant for small teams who patch manually without the aid of enterprise tools so it therefore stands to reason that applications such as SQL, Exchange etc would also be patched alongside windows patching, therefore the dates provided by this script would allow a small team, who patch manually a suitable 'viewport' into their overall patching status. 

# Thanks to the following on Reddit 

u/TumsFestivalEveryDay for the Get-WinEvent code snippet which I modified to suit. 

u/BigHandLittleSlap for pointing out the flaw in my original scripts 'logic' and the system files code which I modified to suit. 
  
u/Semicol0n for teh recommendation to allow single computer query and allow user to determine output which allowed me to convert it to a function.


# Output Example 

![patches](https://i.imgur.com/CMWyWDI.png) 

 
