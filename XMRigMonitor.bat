:: XMRigMonitor 0.2b (https://github.com/MrClappy/XMRigMonitor)
:: Ryan MacNeille 2021

	:: Set global parameters
	@echo off
	mode 56,3
	title XMRigMonitor 0.2b
	setlocal EnableExtensions EnableDelayedExpansion

	:: Verify administrative permissions
    net session >nul 2>&1
    if %errorLevel% == 0 (
		call :LOAD_CONFIG "%~dpn0"
		goto :STARTUP
    ) else (
		mode 52,9
		cls && echo.
		echo  [Error]
		echo.
		echo  XMRigMonitor requires Administrative permissions
		echo.
		echo  Please re-run XMRigMonitor as Administrator
		echo.
		echo  Press any key to exit...
		pause > nul
		exit
    )

:LOAD_CONFIG

	:: -- Load user-defined settings -- ::
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
	
	:: -- Begin Program -- ::
	
:STARTUP

	:: Set global variables
	cd %~dp0
	set WorkingDir=%cd%
	set /a TooFastCrashInt=0
	set "Caller=%computername%$"
	set CPUTempPath=%WorkingDir%\backend\OHMR
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	set "XMLFile=%WorkingDir%\backend\ScheduledTask.xml"
	set DailyLog=%WorkingDir%\backend\logs\Script_Log_%CurrentDate%.txt
	set XMRigCrashCount=%CPUTempPath%\temp\XMRigCrashCount_%CurrentDate%.txt
	set SystemCrashCount=%CPUTempPath%\temp\SystemCrashCount_%CurrentDate%.txt
	
	:: Set EXE and make sure XMRigMonitor is next to it
	if /I not %EXEOverride% == Disabled (
		set EXE=%EXEOverride%
		set EXEName=%EXEOverride%
	) else (
		if %ProxyMode% == Enabled (
			set EXE=xmrig-proxy.exe
			set EXEName=Proxy
		) else (
			set EXE=xmrig.exe
			set EXEName=XMRig
		)
	)
	
	if not exist %WorkingDir%\%EXE% (
		mode 70,9
		cls && echo.
		echo  [Error]
		echo.
		echo  %EXEName% not found in folder: %WorkingDir%
		echo.
		echo  Please unzip XMRigMonitor into the folder containing %EXEName%
		echo.
		echo  Press any key to exit...
		pause > nul
		exit
	)
	
	:: Make sure XMRigMonitor isn't already running for this EXE
	tasklist /v|find "XMRigMonitor 0.2b (%EXEName%)" >nul &&set Lock=True || set Lock=False
	if %Lock% == True (
		echo [%time%] [ Er ] XMRigMonitor Triggered but Already Running >> %DailyLog%
		mode 55,6
		cls && echo.
		echo  [Error]
		echo.
		echo  XMRigMonitor is already running for %EXEName%
		echo.
		echo  Press any key to exit...
		pause > nul
		exit
	)
	
	:: Set Window Title
	title XMRigMonitor 0.2b (%EXEName%)

	:: Check Scheduled Task Status
	if %TaskMode% == Enabled (
		for /f "delims=" %%i in ('type "!XMLFile!" ^& break ^> "!XMLFile!" ') do (
			set "line=%%i"
			>>"!XMLFile!" echo(!line:XMRigVersion=%~f0!
		)
		
		schtasks /Query /TN "XMRigMonitor (%EXEName%)" > nul 2>&1  
		if !errorlevel! == 0 (
			schtasks /Delete /F /TN "XMRigMonitor (%EXEName%)" > nul 2>&1
			schtasks /Create /TN "XMRigMonitor (%EXEName%)" /XML !XMLFile! > nul 2>&1
		) else (
			schtasks /Create /TN "XMRigMonitor (%EXEName%)" /XML !XMLFile! > nul 2>&1
			set "ScheduledTaskChange=[%time%] [Note] Scheduled Task Enabled"
		)
		for /f "delims=" %%i in ('type "!XMLFile!" ^& break ^> "!XMLFile!" ') do (
			set "line=%%i"
			>>"!XMLFile!" echo(!line:%~f0=XMRigVersion!
		)
	) else (
		schtasks /Query /TN "XMRigMonitor (%EXEName%)" > nul 2>&1
		if !errorlevel! == 0 (
			schtasks /Delete /F /TN "XMRigMonitor (%EXEName%)" > nul 2>&1
			set "ScheduledTaskChange=[%time%] [Note] Scheduled Task Disabled"
		)
	)

	:: Check if program was run by User or Scheduled Task
	if %username% == %Caller% (
		set Caller=Task
		if defined ScheduledTaskChange (
			echo %ScheduledTaskChange% >> %DailyLog%
		)
		goto SYSTEM_CRASH
	) else (
		set Caller=User
		echo [%time%] [Note] XMRigMonitor Started Manually >> %DailyLog%
		if defined ScheduledTaskChange (
			echo %ScheduledTaskChange% >> %DailyLog%
		)
	) 

	:: Check if XMRig was already running
	for /F %%x in (
		'tasklist /NH /FI "IMAGENAME eq %EXE%"'
		) do ( 
			if %%x == %EXE% (
				echo [%time%] [Note] %EXEName% already running, script monitoring... >> %DailyLog% && goto PULSE
			)
	)
	
	:: Start XMRig if it's not running
	start /MIN %WorkingDir%\%EXE% %EXEParameters%
	echo [%time%] [Note] Initial %EXEName% Triggered, script monitoring... >> %DailyLog%

:PULSE

	:: Recurring loop to check if XMRig is still running
	for /F %%x in (
		'tasklist /NH /FI "IMAGENAME eq %EXE%"'
		) do (
			if %%x == %EXE% (
				if %Caller% == User (
					goto STATS
				) else (
					goto FEATURE_CHECK
				)
			)
		)
	)
	start /MIN %WorkingDir%\%EXE% %EXEParameters%
	for /F %%x in (
		'tasklist /NH /FI "IMAGENAME eq %EXE%"'
		) do (
			if %%x == %EXE% goto XMRIG_CRASH
			)
	goto PULSE

:STATS

	:: Get daily statistics if program was run by user
	if not exist %XMRigCrashCount% (
		del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul
		>%XMRigCrashCount% echo 0
	)
	set /p XMRigCrashInt=<%XMRigCrashCount%
	if %XMRigCrashInt% gtr 0 set CrashOccurred=True
	if not exist %SystemCrashCount% (
		del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul
		>%SystemCrashCount% echo 0
	)
	set /p SystemCrashInt=<%SystemCrashCount%
	if %SystemCrashInt% gtr 0 set CrashOccured=True	
	
	:: Display statistics in CMD window every PulseTime seconds
	if %CPUMonitor% == Enabled (
		if "%CPUTemp%" == "" (
			cls && echo.
			echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running - Checking every %PulseTime%seconds
		) else (
			mode 60,3 && cls && echo.
			echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running [%CPUTemp%C] - Checking every %PulseTime%seconds
		)
	) else (
		echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running - Checking every %PulseTime%seconds
	)
	if "%CrashOccurred%" == "True" (
		if %CPUMonitor% == Enabled (
			if "%CPUTemp%" == "" (
				mode 54,5 && cls && echo.
				echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running - Checking every %PulseTime%seconds && echo   Today: System Crashes = [%SystemCrashInt%]   App Crashes = [%XMRigCrashInt%]
			) else (
				mode 60,5 && cls && echo.
				echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running [%CPUTemp%C] - Checking every %PulseTime%seconds && echo     Today: System Crashes = [%SystemCrashInt%]     App Crashes = [%XMRigCrashInt%]
			)
		) else (
			mode 54,5 && cls && echo.
			echo  [%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%] %EXEName% Running - Checking every %PulseTime%seconds && echo     Today: System Crashes = [%SystemCrashInt%]     App Crashes = [%XMRigCrashInt%]
		)
	)
	goto FEATURE_CHECK
	
:FEATURE_CHECK

	:: Check and run any enabled feature
	if %CPUMonitor% == Enabled (
		set /a AdjustedPulseTime=%PulseTime%-5
		timeout /t !AdjustedPulseTime! > nul
		call :CPU_TEMP
	) else (
		timeout /t %PulseTime% > nul
	)
	
	if %TangoMode% == Enabled (
		call :TANGO_MODE
	)
	goto PULSE
	
	
:XMRIG_CRASH

	:: Check to see if XMRig is crashing immediately, this can occur if the executable is corrupt
	set "endTime=%time: =0%"
	set "end=!endTime:%time:~8,1%=%%100)*100+1!"  &  set "start=!startTime:%time:~8,1%=%%100)*100+1!"
	set /A "cc=elap%%100+100,elap/=100,ss=elap%%60+100,elap/=60,mm=elap%%60+100,hh=elap/60+100"
	
	if "%startTime%"=="" (
		goto XMRIG_RECOVERY
	) else (
		if %ss:~1% lss 5 (
		set /a TooFastCrashInt=%TooFastCrashInt%+1
			if %TooFastCrashInt% geq 10 (
				echo [%time%] [ Er ] %EXEName% is crashing too frequently - Exiting >>%DailyLog%
				exit
			)
		)
	)
	goto XMRIG_RECOVERY

	
:XMRIG_RECOVERY

	:: When App Crashes, update the daily crash count and email the user (if configured)
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %XMRigCrashCount% (
		del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul 
		>%XMRigCrashCount% echo 0
	)
	for /f " delims==" %%i in (
		%XMRigCrashCount%
		) do (
			set /A XMRigCrashInt= %%i+1 >nul
		)
	)
	if %XMRigCrashInt% gtr 0 (
		>%XMRigCrashCount% echo %XMRigCrashInt%
	)
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog%
	echo [%time%] [Warn] %EXEName% Crash Recovered %XMRigCrashInt% times, script monitoring... >> %DailyLog%
	
	if %CPUMonitor% == Enabled (
		type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	)
	if %EmailOnXMRigCrash% == Enabled (
		call %WorkingDir%\backend\EmailConfig.bat %EmailAccount% "%EmailPassword%" %EmailOnXMRigCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	)
	set "startTime=%time: =0%"
	goto PULSE

:SYSTEM_CRASH

	:: When the system crashes, update the daily crash count and start the recovery process
	set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
	if not exist %SystemCrashCount% (
		del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul 
		>%SystemCrashCount% echo 0
	)
	
	for /f " delims==" %%i in (
		%SystemCrashCount%
		) do (
			set /A SystemCrashInt= %%i+1  >nul
		)
	)
	if %SystemCrashInt% gtr 0 (
		>%SystemCrashCount% echo %SystemCrashInt%
	)
	call %WorkingDir%\backend\LogCleaner.bat %DailyLog% >nul
	echo [%time%] [Warn] System Crashed %SystemCrashInt% times, checking network... >> %DailyLog%
	set /a NetAttempt=0 
	goto SYSTEM_CRASH_RECOVERY

:SYSTEM_CRASH_RECOVERY

	::Check to see if the system has internet connectivity and restart XMRig once confirmed

	ping -n 2 8.8.8.8 | find "TTL=" >nul 2>&1
	if !errorlevel! equ 1 (
		ping -n 6 8.8.8.8 | find "TTL=" >nul 2>&1
		if !errorlevel! equ 1 (
			set /a NetAttempt=%NetAttempt%+1
			if !NetAttempt! geq 5 (
				echo [%time%] [Warn] Network Still Down... >> %DailyLog%   
				set /a NetAttempt=0
				goto SYSTEM_CRASH_RECOVERY
			) else (
				goto SYSTEM_CRASH_RECOVERY
			)
		) else (
			if !NetAttempt! geq 5 (
				echo [%time%] [Note] Network Recovered >> %DailyLog%
			)
		)
	) 
	for /F %%x in (
		'tasklist /NH /FI "IMAGENAME eq %EXE%"'
		) do (
			if %%x == %EXE% goto PULSE
			)
	start /MIN %WorkingDir%\%EXE% %EXEParameters%
	for /F %%x in (
		'tasklist /NH /FI "IMAGENAME eq %EXE%"'
		) do (
			if %%x == %EXE% goto SUCCESS
		)
	)	

:SUCCESS

	:: After a system crash has been recovered, email the user (if configured) and continue monitoring
	echo [%time%] [Note] %EXEName% Running, script monitoring... >> %DailyLog%
	if %CPUMonitor% == Enabled (
		type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
	)
	if %EmailOnSystemCrash% == Enabled (
		call %WorkingDir%\backend\EmailConfig.bat %EmailAccount% "%EmailPassword%" %EmailOnSystemCrashSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
	)
	goto PULSE
	
:TANGO_MODE

	ping -n 1 %MinerName% | find "TTL=" > nul
		if errorlevel 1 (
			if /I not "%TangoMinerDown%" == "True" (
				echo [%time%] [ Er ] Tango Mode miner %MinerName%failed to respond >> %DailyLog%
				call %WorkingDir%\backend\EmailConfig.bat %EmailAccount% "%EmailPassword%" %EmailOnTangoDownSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
				set TangoMinerDown=True
			)
		) else (
			if "%TangoMinerDown%" == "True" (
				echo [%time%] [ Er ] Tango Mode miner %MinerName%connectivity recovered >> %DailyLog%
				call %WorkingDir%\backend\EmailConfig.bat %EmailAccount% "%EmailPassword%" %EmailOnTangoUpSubject% %DailyLog% %EmailRecipient% %SMTPServer% %SMTPPortNumber%
			)
			set TangoMinerDown=False
			goto PULSE
		)
	)
	goto PULSE
	
:CPU_TEMP

	:: As long as XMRig is running, get CPU temperature every PulseTime seconds	
	start /WAIT /B %CPUTempPath%\OpenHardwareMonitorReport.exe ReportToFile -f %CPUTempPath%\temp\OHMR.tmp
	
	for /f "tokens=2 delims=:" %%a in (
		'type %CPUTempPath%\temp\OHMR.tmp^|find "/amdcpu/0/temperature/0"'
		) do (
			echo %%a > %CPUTempPath%\temp\ParsedTemp.tmp
		)
	)
	for /f "tokens=2 delims=:" %%a in (
		'type %CPUTempPath%\temp\OHMR.tmp^|find "/intelcpu/0/temperature/0"'
		) do (
			echo %%a > %CPUTempPath%\temp\ParsedTemp.tmp
		)
	)
	if not exist %CPUTempPath%\temp\ParsedTemp.tmp (
		set CPUMonitor=Disabled 
		echo [%time%] [ Er ] Attempt to get CPU temperature failed, feature disabled >> %DailyLog%
		goto PULSE
	)
	for /f "tokens=3" %%a in (
		%CPUTempPath%\temp\ParsedTemp.tmp
		) do (
			set "ParsedTemp=%%a"
		)
	)
	call :ROUND %ParsedTemp% CPUTemp
	if %CPUTemp% gtr 0 echo [%time%] [Note] Last CPU Temp: %CPUTemp%C > %CPUTempPath%\temp\LastTemp.tmp
	del %CPUTempPath%\temp\OHMR.tmp && del %CPUTempPath%\temp\ParsedTemp.tmp
	
:ROUND <Input> <Output>

	for /f "tokens=1,2 delims=." %%A in ("%~1") do set "X=%%~A" & set "Y=%%~B0"
	if %Y:~0,1% geq 5 set /a "X+=1"
	set "%~2=%X%" >nul 2>&1
	exit /b 0