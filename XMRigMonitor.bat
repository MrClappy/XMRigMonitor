@echo off
setlocal EnableExtensions EnableDelayedExpansion
title XMRigMonitor 0.2b
mode 60,3

:: XMRigMonitor 0.2b (https://github.com/MrClappy/XMRigMonitor)
:: Ryan MacNeille 2021

:: -- Load user-defined settings -- ::
call :LOAD_CONFIG "%~dpn0"
goto :STARTUP

:LOAD_CONFIG
	echo Loading Configuration...
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

	:: Check Scheduled Task status
	if %ScheduledTask% == Enabled (
		for /f "delims=" %%i in ('type "%XMLFile%" ^& break ^> "%XMLFile%" ') do (
			set "line=%%i"
			setlocal enabledelayedexpansion
			>>"%XMLFile%" echo(!line:%OldVersion%=%NewVersion%!
			endlocal
		)
		schtasks /Query /TN "XMRigMonitor" >nul
		if %errorlevel% EQU 0 (schtasks /Delete /F /TN "XMRigMonitor" >nul)
		schtasks /Create /TN XMRigMonitor /XML %XMLFile% >nul
		for /f "delims=" %%i in ('type "%XMLFile%" ^& break ^> "%XMLFile%" ') do (
			set "line=%%i"
			setlocal enabledelayedexpansion
			>>"%XMLFile%" echo(!line:%NewVersion%=%OldVersion%!
			endlocal
		)
	) else (
		schtasks /Query /TN "XMRigMonitor" 2>nul
		if %errorlevel% EQU 0 (schtasks /Delete /F /TN "XMRigMonitor" 2>nul)
	)
	
	:: Check if program was run by User or Scheduled Task
	if not %username% == %Caller% (echo [%time%] [Note] Script Started Manually >> %DailyLog%) else (goto SYSTEM_CRASH)
	
	:: Check if XMRig was already running & start it if not
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% echo [%time%] [Note] XMRig already running, script monitoring... >> %DailyLog% && goto PULSE
	start /MIN %WorkingDir%\xmrig.exe
	echo [%time%] [Note] Initial XMRig Triggered, script monitoring... >> %DailyLog%
	goto PULSE

:PULSE
	:: Recurring loop to check if XMRig is still running
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do (
		if %%x == %EXE% (
			goto STATS
		)
	)
	start /MIN %WorkingDir%\xmrig.exe
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do (
		if %%x == %EXE% (
			goto XMRIG_CRASH
		)
	)
	goto PULSE
	
:STATS
	:: Display daily statistics if program was run by user
	if %username% == %Caller% (
		if %CPUMonitor% == Enabled (
			goto CPU_TEMP
		) else (
			goto PULSE
		)
	)
	:: If it's a new day, reset XMRig crash counter
	if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
	set /p XMRigCrashInt=<%XMRigCrashCount%
	
	:: If it's a new day, reset system crash counter
	if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
	set /p SystemCrashInt=<%SystemCrashCount%
	
	:: Display last pulse status
	cls && echo. && echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] XMRig Running (Checking every %PulseTime%seconds)
	
	:: If crashes have occurred today, display stats
	if %XMRigCrashInt% gtr 0 do (
		set CrashOccurred=True
	)
	if %SystemCrashInt% gtr 0 do (
		set CrashOccured=True	
	)
	if "%CrashOccurred%" == "True" do (
		cls && echo.
		echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] XMRig Running (Checking every %PulseTime%seconds)
		echo  Today: System Crashes = [%SystemCrashInt%] XMRig Crashes = [%XMRigCrashInt%]
	)
	
	:: Wait for PulseTime seconds before continuing
	timeout /t %PulseTime% >nul
	if %CPUMonitor% == "Enabled" do (
		goto CPU_TEMP
	) else (
		goto PULSE
	)

:CPU_TEMP
	:: As long as XMRig is running, get CPU temperature every PulseTime seconds	
	Start /WAIT /B %CPUTempPath%\OpenHardwareMonitorReport.exe ReportToFile -f %CPUTempPath%\temp\OHMR.tmp
	for /f "tokens=2 delims=:" %%a in ('type %CPUTempPath%\temp\OHMR.tmp^|find "/amdcpu/0/temperature/0"') do (
		echo %%a > %CPUTempPath%\temp\ParsedTemp.tmp
	)
	if not exist %CPUTempPath%\temp\ParsedTemp.tmp set CPUMonitor=Disabled && echo [%time%] [Erro] Attempt to get CPU temperature failed, feature disabled >> %DailyLog% && goto PULSE
	for /f "tokens=3" %%a in (%CPUTempPath%\temp\ParsedTemp.tmp) do set ParsedTemp=%%a 2>nul
	if %ParsedTemp% gtr 0 echo [%time%] [Note] Last CPU Temp: %ParsedTemp%C > %CPUTempPath%\temp\LastTemp.tmp 2>nul
	del %CPUTempPath%\temp\OHMR.tmp && del %CPUTempPath%\temp\ParsedTemp.tmp 2>nul
	goto PULSE

:XMRIG_CRASH
	:: When XMRig crashes, update the daily crash count and email the user (if configured)
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
	for /f " delims==" %%i in (%XMRigCrashCount%) do set /A XMRigCrashInt= %%i+1 >nul
	if %XMRigCrashInt% gtr 0 >%XMRigCrashCount% echo %XMRigCrashInt%
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog%
	echo [%time%] [Warn] XMRig Crash Recovered %XMRigCrashInt% times, script monitoring... >> %DailyLog%
	if "%CPUMonitor%" == "Enabled " type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	if "%EmailOnXMRigCrash%" == "Enabled " call %WorkingDir%\backend\EmailConfig.bat 1 %EmailAccount% %EmailPassword% %EmailOnXMRigCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	goto PULSE


:SYSTEM_CRASH
	:: When the system crashes, update the daily crash count and start the recovery process
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
	for /f " delims==" %%i in (%SystemCrashCount%) do set /A SystemCrashInt= %%i+1  >nul
	if %SystemCrashInt% gtr 0 >%SystemCrashCount% echo %SystemCrashInt%
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog% >nul
	echo [%time%] [Warn] System Crashed %SystemCrashInt% times, checking network... >> %DailyLog%
	goto RECOVERY

:RECOVERY
	::Check to see if the system has internet connectivity and restart XMRig once confirmed
	ping -n 1 192.168.1.1 | find "TTL=" > nul
	if errorlevel 1 (
		timeout /t 5 > nul
		ping -n 1 192.168.1.1 | find "TTL=" > nul
		if errorlevel 1 (
			echo [%time%] [Warn] Network Still Down... >> %DailyLog%    
			goto RECOVERY
		) else (goto RECOVERY)
	) else (
		echo [%time%] [Note] Network Recovered >> %DailyLog%
		for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto PULSE
		start /MIN %WorkingDir%\xmrig.exe
		for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto SUCCESS
		)
		
:SUCCESS
	:: After a system crash has been recovered, email the user (if comfigured) and continue monitoring
	echo [%time%] [Note] XMRig Running, script monitoring... >> %DailyLog%
	if "%CPUMonitor%" == "Enabled " type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	if "%EmailOnSystemCrash%" == "Enabled " call %WorkingDir%\backend\EmailConfig.bat 2 %EmailAccount% %EmailPassword% %EmailOnSystemCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	goto PULSE