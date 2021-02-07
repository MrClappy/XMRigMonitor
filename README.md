# XMRig Monitor

## Project Description & Current State

XMRig Monitor is a personal project intended to serve as an automated watchdog for XMRig in Windows environments. Its primary purpose is to
maintain XMRig uptime on unstable systems and provide event logs when optimizing hardware for mining.

### Primary features:

- Restarts XMRig executable in the event of an application crash or system crash
- Sends email notifications containing detailed logs of events
- Monitors CPU temperature metrics to correlate crash root cause
- User Mode = Displays daily crash statistics or Scheduled Task Mode = Runs silently when computer is idle

### Current State:

The project currently exists as a set of Batch and Powershell scripts along with executables from the open-source project OpenHardwareMonitor
(https://github.com/openhardwaremonitor/). Scripts are currently configured for and tested on my personal hardware and will require considerable
manipulation to deploy elsewhere. I intend to continue using Batch to build out the logic for the project until it reaches a consistently stable
point, then will port to either Python our PowerShell - I suspect the project will remain exclusively for Windows environments.

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
backend/LogCleaner.bat	| Supporting batch to strip leading & trailing spaces from log if system crashes during write
backend/ScheduledTask.xml		| Settings file for Windows Task Scheduler

## Download & Installation
------------

Installation instructions will remain empty until a consistently stable status is reached. Latest pre-release [(v0.2b)](https://github.com/MrClappy/XMRigMonitor/releases/tag/v0.2b) is availabile for download.

## Configuration File Options
------------

Setting            | Description             | Options
--------------- | ----------------- | ------------------------------
PulseTime		| How often XMRigMonitor checks on XMRig  | Seconds (s)
CPUMonitor		| Adds a CPU Temperature check every PulseTime | Enabled / Disabled
ScheduledTask		| Creates a task to run XMRigMonitor on boot and idle state  | Enabled / Disabled
EmailOnXMRigCrash | Sends an email when XMRig crashes | True / False
EmailOnXMRigCrashSubject  | Subject line of the email when XMRig crashes | Text string in quotes
EmailOnSystemCrash  | Sends an email when the system crashes  | True / False
EmailOnSystemCrashSubject | Subject line of the email when the system crashes | Text string in quotes
EmailAccount  | Email address used to send emails | Email address in plain text
EmailPassword | Password of email address used to send emails  |  Password in plain text
SMTPServer  | SMTP server address used to send emails | Server address in plain text
SMTPPortNumber  | SMTP port number used to send emails  | Port number in plain text
EmailRecipient  | Email address to receive emails | Email address in plain text

### Known Issues

- CPU temperature monitoring only supports AMD CPUs currently
- Scheduled Tasks have zero user-configurable parameters, adjustments must be made manually in Task Scheduler
