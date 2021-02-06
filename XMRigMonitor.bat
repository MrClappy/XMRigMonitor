@echo off
REM XMRigMonitor 0.2b (https://github.com/MrClappy/XMRigMonitor)
REM Ryan MacNeille 2021

REM Configure Settings:
set EXE=xmrig.exe
set PulseTime=10
set WorkingPath=C:\Users\Ryan\Desktop\xmrig-6.8.1

REM -------------------
title XMRigMonitor 0.2b
mode 60,3
echo.
echo  Checking XMRig status...
setlocal EnableExtensions
setlocal EnableDelayedExpansion

REM set Time=%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2%
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
set DailyLog=%WorkingPath%\backend\logs\Script_Log_%CurrentDate%.txt
set CPUTempPath=%WorkingPath%\backend\OHMR
set XMRigCrashCount=%CPUTempPath%\temp\XMRigCrashCount_%CurrentDate%.txt
set SystemCrashCount=%CPUTempPath%\temp\SystemCrashCount_%CurrentDate%.txt

if %username% == Ryan (echo [%date% %time%] Script Started Manually >> %DailyLog%) else (goto SYSTEM_CRASH)
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% echo [%date% %time%] XMRig already running, script monitoring... >> %DailyLog% && goto PULSE
start /MIN %WorkingPath%\xmrig.exe
echo [%date% %time%] Initial XMRig Triggered, script monitoring... >> %DailyLog%
goto PULSE

:PULSE
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto FOUND
start /MIN %WorkingPath%\xmrig.exe
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto XMRIG_CRASH
goto PULSE

:FOUND
Start /WAIT /B %CPUTempPath%\OpenHardwareMonitorReport.exe ReportToFile -f %CPUTempPath%\temp\OHMR.tmp --IgnoreMonitorGPU --IgnoreMonitorHDD --IgnoreMonitorRAM --IgnoreMonitorFanController
for /f "tokens=2 delims=:" %%a in ('type %CPUTempPath%\temp\OHMR.tmp^|find "/amdcpu/0/temperature/0"') do (
  echo %%a > %CPUTempPath%\temp\ParsedTemp.tmp
)
for /f "tokens=3" %%a in (%CPUTempPath%\temp\ParsedTemp.tmp) do set ParsedTemp=%%a
if %ParsedTemp% gtr 0 echo [%date% %time%] Last CPU Temp: %ParsedTemp%C > %CPUTempPath%\temp\LastTemp.tmp
del %CPUTempPath%\temp\OHMR.tmp && del %CPUTempPath%\temp\ParsedTemp.tmp
goto STATS

:STATS
if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
set /p XMRigCrashInt=<%XMRigCrashCount%
set /p SystemCrashInt=<%SystemCrashCount%
if %XMRigCrashInt% gtr 0 set CrashOccurred=True
if %SystemCrashInt% gtr 0 set CrashOccured=True
cls && echo. && echo  XMRig Running at%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2% (Checking every %PulseTime% seconds)
if "%CrashOccurred%" == "True" mode 60,4 && cls && echo. && echo  XMRig running at%TIME:~0,2%:%TIME:~3,2%:%TIME:~6,2% (Checking every %PulseTime% seconds) && echo  Today: System Crashes = [%SystemCrashInt%] XMRig Crashes = [%XMRigCrashInt%]
timeout /t %PulseTime% > nul
goto PULSE

:XMRIG_CRASH
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\XMRigCrashCount_*.txt 2>nul & >%XMRigCrashCount% echo 0
for /f " delims==" %%i in (%XMRigCrashCount%) do set /A XMRigCrashInt= %%i+1 >nul
if %XMRigCrashInt% gtr 0 >%XMRigCrashCount% echo %XMRigCrashInt%
call %WorkingPath%\backend\LogCleaner.bat %DailyLog% >nul
echo [%date% %time%] XMRig Crash Recovered %XMRigCrashInt% times, script monitoring... >> %DailyLog%
type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
call %WorkingPath%\backend\EmailConfig.bat 1
goto PULSE

:SYSTEM_CRASH
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\SystemCrashCount_*.txt 2>nul & >%SystemCrashCount% echo 0
for /f " delims==" %%i in (%SystemCrashCount%) do set /A SystemCrashInt= %%i+1  >nul
REM if %SystemCrashInt% gtr 0 >%SystemCrashCount% echo %SystemCrashInt%
call %WorkingPath%\backend\LogCleaner.bat %DailyLog% >nul
echo [%date% %time%] System Crashed %SystemCrashInt% times, checking network... >> %DailyLog%
goto RECOVERY

:RECOVERY
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
	start /MIN %WorkingPath%\xmrig.exe
	for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto SUCCESS
	)
	
:SUCCESS
echo [%date% %time%] XMRig Running, script monitoring... >> %DailyLog%
type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
call %WorkingPath%\backend\EmailConfig.bat 2
goto PULSE