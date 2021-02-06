XMRig Monitor
====================

### Project Intent & Current State

XMRig Monitor is a personal project intended to serve as an automated watchdog for XMRig in Windows environments. Its primary purpose is to
maintain XMRig uptime on unstable systems and provide event logs when optimizing hardware for mining.

Primary features:

- Restarts XMRig executable in the event of an application crash or system crash
- Sends email notifications containing detailed logs of events
- Monitors CPU temperature metrics to correlate crash root cause

Current State:

The project currently exists as a set of Batch and Powershell scripts along with executables from the open-source project OpenHardwareMonitor
(https://github.com/openhardwaremonitor/). Scripts are currently configured for and tested on my personal hardware and will require considerable
manipulation to deploy elsewhere. I intend to continue using Batch to build out the logic for the project until it reaches a consistently stable
point, then will port to either Python our PowerShell - I suspect the project will remain exclusively for Windows environments.

### Files Description

Subdirectories:

Name            | Description
--------------- | -------------------------------------------------
Backend/		| Contains all supporting scripts and executables
Backend/OHMR		| Executables for CPU temperature monitoring
Backend/OHMR/temp		| Temporary files for CPU temperature parsing & crash counters
logs		| Rotating logs of daily events


Particular files:

Name            | Description
--------------- | ---------------------------------------------------------------
README.md	| This file
XMRigMonitor.bat		| Main project batch
EmailConfig.bat	| Supporting batch to configure email settings & notification types
Emailer.ps1		| Email trigger script to grab log contents and send notifications
LogCleaner.bat	| Supporting batch to strip leading & trailing spaces from log if system crashes during write


Installation
------------

Installation instructions will remain empty until a consistently stable status is reached.
