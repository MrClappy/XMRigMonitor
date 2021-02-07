@echo off
setlocal EnableExtensions EnableDelayedExpansion
title XMRigMonitor 0.2b
mode 60,3
:: batbox /h 0

:: XMRigMonitor 0.2b (https://github.com/MrClappy/XMRigMonitor)
:: Ryan MacNeille 2021

:: -- Load user-defined settings -- ::
call :LOAD_CONFIG "%~dpn0"
call :STARTUP
@exit /B 0

:LOAD_CONFIG
	echo  Loading Configuration...
	set ConfigFile=%1
	set ConfigFile=%ConfigFile:"=%

	for %%c in (
		"!ConfigFile!.conf"
	) do (
		if exist "%%c" (
			for /F "usebackq delims=" %%v in (%%c) do (set %%v 2>nul)
		)
	)

	:: -------- Begin Program -------- ::
:STARTUP
	:: Set global variables
	cd %~dp0
	set WorkingDir=%cd%
	set EXE=xmrig.exe
	set "XMLFile=%WorkingDir%\backend\ScheduledTask.xml"
	set "OldVersion=XMRigVersion"
	set "NewVersion=%~f0"
	set "Caller=%computername%$"
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	set DailyLog=%WorkingDir%\backend\logs\Script_Log_%CurrentDate%.txt
	set CPUTempPath=%WorkingDir%\backend\OHMR
	set XMRigCrashCount=%CPUTempPath%\temp\XMRigCrashCount_%CurrentDate%.txt
	set SystemCrashCount=%CPUTempPath%\temp\SystemCrashCount_%CurrentDate%.txt
	
	:: Check Scheduled Task
	if %ScheduledTask% == Enabled (
		for /f "delims=" %%i in ('type "%XMLFile%" ^& break ^> "%XMLFile%" ') do (
			set "line=%%i"
			setlocal enabledelayedexpansion
			>>"%XMLFile%" echo(!line:%OldVersion%=%NewVersion%!
			endlocal
		)
		schtasks /Query /TN "XMRigMonitor" >nul
		if %errorlevel% NEQ 0 (schtasks /Delete /TN "XMRigMonitor")
		schtasks /Create /TN XMRigMonitor /XML %XMLFile%
		for /f "delims=" %%i in ('type "%XMLFile%" ^& break ^> "%XMLFile%" ') do (
			set "line=%%i"
			setlocal enabledelayedexpansion
			>>"%XMLFile%" echo(!line:%NewVersion%=%OldVersion%!
			endlocal
		)
	)
	
	:: Check if program was run by User or Scheduled Task
	if not %username% == %Caller% (echo [%date% %time%] Script Started Manually >> %DailyLog%) else (goto SYSTEM_CRASH)
	
	:: Check if XMRig was already running & start it if not
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% echo [%date% %time%] XMRig already running, script monitoring... >> %DailyLog% && goto PULSE
	start /MIN %WorkingDir%\xmrig.exe
	echo [%date% %time%] Initial XMRig Triggered, script monitoring... >> %DailyLog%
	goto PULSE

:PULSE
	:: Recurring loop to check if XMRig is still running
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto STATS
	start /MIN %WorkingDir%\xmrig.exe
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto XMRIG_CRASH
	goto PULSE

:CPU_TEMP
	:: As long as XMRig is running, get CPU temperature every PulseTime seconds	
	Start /WAIT /B %CPUTempPath%\OpenHardwareMonitorReport.exe ReportToFile -f %CPUTempPath%\temp\OHMR.tmp --IgnoreMonitorGPU --IgnoreMonitorHDD --IgnoreMonitorRAM --IgnoreMonitorFanController
	for /f "tokens=2 delims=:" %%a in ('type %CPUTempPath%\temp\OHMR.tmp^|find "/amdcpu/0/temperature/0"') do echo %%a > %CPUTempPath%\temp\ParsedTemp.tmp
	for /f "tokens=3" %%a in (%CPUTempPath%\temp\ParsedTemp.tmp) do set ParsedTemp=%%a
	if %ParsedTemp% gtr 0 echo [%date% %time%] Last CPU Temp: %ParsedTemp%C > %CPUTempPath%\temp\LastTemp.tmp
	del %CPUTempPath%\temp\OHMR.tmp && del %CPUTempPath%\temp\ParsedTemp.tmp
	goto PULSE

:STATS
	:: Display daily statistics if program was run by user
	if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
	if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
	set /p XMRigCrashInt=<%XMRigCrashCount%
	set /p SystemCrashInt=<%SystemCrashCount%
	if %XMRigCrashInt% gtr 0 set CrashOccurred=True
	if %SystemCrashInt% gtr 0 set CrashOccured=True	
	cls && echo. && echo  XMRig Running at %TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2% (Checking every %PulseTime% seconds)
	if "%CrashOccurred%" == "True" cls && echo. && echo  XMRig running at%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2% (Checking every %PulseTime% seconds) && echo  Today: System Crashes = [%SystemCrashInt%] XMRig Crashes = [%XMRigCrashInt%]
	
	:: Commands for button draw, however prompt doesn't refresh after this is called. Once button is pressed, prompt will refresh.
	:: Call %WorkingDir%\button.bat  23 4 "Open Log" # Press
	:: %WorkingDir%\Getinput.exe /m %Press% /h 70
	:: if %errorlevel%==1 (notepad %DailyLog%)	

	:: May need to separate timeout /t %PulseTime% into a loop like this (if loop == PulseTime goto next) where each loop calls timeout for 1 sec & call button refresh
	:: Also look into CALL instead of GOTO 
	
	:: set loop=0
	:: :loop
	:: echo hello world
	:: set /a loop=%loop%+1 
	:: if "%loop%"=="2" goto next
	:: goto loop

	:: :next

	timeout /t %PulseTime% > nul
	if "%CPUMonitor%" == "Disabled" goto PULSE
	goto CPU_TEMP

:XMRIG_CRASH
	:: When XMRig crashes, update the daily crash count and email the user (if configured)
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
	for /f " delims==" %%i in (%XMRigCrashCount%) do set /A XMRigCrashInt= %%i+1 >nul
	if %XMRigCrashInt% gtr 0 >%XMRigCrashCount% echo %XMRigCrashInt%
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog%
	echo [%date% %time%] XMRig Crash Recovered %XMRigCrashInt% times, script monitoring... >> %DailyLog%
	if "%CPUMonitor%" == "Enabled" type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	if "%EmailOnXMRigCrash%" == "True" call %WorkingDir%\backend\EmailConfig.bat 1 %EmailAccount% %EmailPassword% %EmailOnXMRigCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	goto PULSE

:SYSTEM_CRASH
	:: When the system crashes, update the daily crash count and start the recovery process
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
	for /f " delims==" %%i in (%SystemCrashCount%) do set /A SystemCrashInt= %%i+1  >nul
	if %SystemCrashInt% gtr 0 >%SystemCrashCount% echo %SystemCrashInt%
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog% >nul
	echo [%date% %time%] System Crashed %SystemCrashInt% times, checking network... >> %DailyLog%
	goto RECOVERY
	pause

:RECOVERY
	::Check to see if the system has internet connectivity and restart XMRig once confirmed
	ping -n 1 192.168.1.1 | find "TTL=" > nul
	if errorlevel 1 (
		timeout /t 5 > nul
		ping -n 1 192.168.1.1 | find "TTL=" > nul
		if errorlevel 1 (
			echo [%date% %time%] Network Still Down... >> %DailyLog%    
			goto RECOVERY
		) else (goto RECOVERY)
	) else (
		echo [%date% %time%] Network Recovered >> %DailyLog%
		for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto PULSE
		start /MIN %WorkingDir%\xmrig.exe
		for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto SUCCESS
		)
		
:SUCCESS
	:: After a system crash has been recovered, email the user (if comfigured) and continue monitoring
	echo [%date% %time%] XMRig Running, script monitoring... >> %DailyLog%
	if "%CPUMonitor%" == "Enabled" type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	if "%EmailOnSystemCrash%" == "True" call %WorkingDir%\backend\EmailConfig.bat 2 %EmailAccount% %EmailPassword% %EmailOnSystemCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	goto PULSE
