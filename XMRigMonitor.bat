REM XMRigMonitor 0.2b (https://github.com/MrClappy/XMRigMonitor)
REM Ryan MacNeille 2021
@echo off
REM Configure Settings:
set EXE=xmrig.exe
set PulseTime=10
set WorkingPath=C:\Users\Ryan\Desktop\xmrig-6.8.1

REM -------------------
title XMRigMonitor 0.2b
mode 48,3
echo.
echo  Starting up...
setlocal EnableExtensions
setlocal EnableDelayedExpansion

set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
set DailyLog=%WorkingPath%\backend\logs\Script_Log_%CurrentDate%.txt
set CPUTempPath=%WorkingPath%\backend\OHMR
set XMRigCrashCount=%CPUTempPath%\temp\XMRigCrashCount_%CurrentDate%.rtf
set SystemCrashCount=%CPUTempPath%\temp\SystemCrashCount_%CurrentDate%.txt

:STARTUP
if %username% == Ryan (echo [%date% %time%] Script Started Manually >> %DailyLog%) else (goto SYSTEM_CRASH)
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% echo [%date% %time%] XMRig already running, script monitoring... >> %DailyLog% && goto PULSE
start /MIN %WorkingPath%\xmrig.exe
echo [%date% %time%] Initial XMRig Triggered, script monitoring... >> %DailyLog%

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
cls && echo. && echo  [%date% %time%] Still running...
timeout /t %PulseTime% > nul
goto PULSE

:XMRIG_CRASH
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
if not exist %XMRigCrashCount% del /F /Q %CPUTempPath%\temp\*.rtf >nul & >%XMRigCrashCount% echo 0
for /f " delims==" %%i in (%XMRigCrashCount%) do set /A TempCounter= %%i+1 >nul
if %TempCounter% gtr 0 echo %TempCounter% > %XMRigCrashCount% >nul
call %WorkingPath%\backend\LogCleaner.bat %DailyLog% >nul
echo [%date% %time%] XMRig Crash Recovered %TempCounter% times, script monitoring... >> %DailyLog%
type %CPUTempPath%\temp\LastTemp.tmp >> %DailyLog%
call %WorkingPath%\backend\EmailConfig.bat 1
goto PULSE

:SYSTEM_CRASH
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
if not exist %SystemCrashCount% del /F /Q %CPUTempPath%\temp\*.txt >nul & >%SystemCrashCount% echo 0
for /f " delims==" %%i in (%SystemCrashCount%) do set /A TempCounter= %%i+1  >nul
if %TempCounter% gtr 0 echo %TempCounter% > %SystemCrashCount% >nul
call %WorkingPath%\backend\LogCleaner.bat %DailyLog% >nul
echo [%date% %time%] System Crashed %TempCounter% times, checking network... >> %DailyLog%
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