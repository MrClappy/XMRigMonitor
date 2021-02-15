# XMRig Monitor

## Project Description

XMRig Monitor is an automated watchdog for XMRig in Windows 10 environments. Its primary purpose is to maintain XMRig uptime on unstable systems and provide event logs when troubleshooting hardware optimization.

### Primary features:

- Restarts XMRig executable in the event of an application crash
- Sends email notifications containing detailed logs of events
- Monitors CPU temperature metrics to correlate crash root cause
- Displays daily crash statistics
- Scheduled Task Mode: Runs silently on boot & restarts XMRigMonitor in the event of system crash
- Tango Mode: Links two miners together to monitor each other

### Current State:

The project currently exists as a set of Batch and Powershell scripts along with executables from the open source project [OpenHardwareMonitor](https://github.com/openhardwaremonitor/) for CPU temperature monitoring. Scripts are currently tested on both Intel and AMD processors and should not require manipulation to deploy other than setting user-configurable options in the supplied config file. The project will remain exclusively for Windows 10 environments.

## Files Description

### Subdirectories:

Name            | Description
--------------- | -------------------------------------------------
backend/		| Contains all supporting scripts and executables
backend/OHMR		| Executables for CPU temperature monitoring
backend/OHMR/temp		| Temporary files for CPU temperature parsing & crash counters
logs		| Rotating logs of daily events


### Particular files:

Name            | Description
--------------- | ---------------------------------------------------------------
README.md	| This file
XMRigMonitor.bat		| Main project batch
XMRigMonitor.conf		| User-configurable settings file
backend/EmailConfig.bat	| Supporting batch to call email notification types
backend/Emailer.ps1		| Email trigger script to grab log contents and send notifications
backend/LogCleaner.bat	| Supporting batch to strip extra spaces from log if system crashes during write
backend/ScheduledTask.xml		| Settings file for Windows Task Scheduler

## Releases & Setup
------------
The latest stable pre-release [(v0.2b)](https://github.com/MrClappy/XMRigMonitor/releases/tag/v0.2b) is availabile for download. The contents
of the zip should be copied into the XMRig folder alongside the XMRig executable. Use XMRigMonitor.conf to set preferences then run 
XMRigMonitor.bat as administrator.

### XMRigMonitor.conf Options

Setting            | Description             | Options
--------------- | ----------------- | ------------------------------
PulseTime		| How often XMRigMonitor checks on XMRig  | Seconds
CPUMonitor		| Adds a CPU Temperature check every PulseTime | Enabled / Disabled
ScheduledTaskMode		| Creates a task to run XMRigMonitor silently on boot | Enabled / Disabled
EmailOnXMRigCrash | Sends an email when XMRig crashes | Enabled / Disabled
EmailOnXMRigCrashSubject  | Subject line of the email when XMRig crashes | Text string in quotes
EmailOnSystemCrash  | Sends an email when the system crashes  | Enabled / Disabled
EmailOnSystemCrashSubject | Subject line of the email when the system crashes | Text string in quotes
EmailOnTangoDownSubject | Subject line of the email when Tango disconnects | Text string in quotes
EmailOnTangoUpSubject | Subject line of the email when Tango recovers | Text string in quotes
EmailAccount  | Email address used to send emails | Email address
EmailPassword | Password of email address used to send emails  |  Plain text password
SMTPServer  | SMTP server address used to send emails | Server address
SMTPPortNumber  | SMTP port number used to send emails  | Port number
EmailRecipient  | Email address to receive emails | Email address
TangoMode | Adds a connectivity check for a second miner | Enabled / Disabled
MinerName | Sets the Tango Mode computer name to check | Computer Name
