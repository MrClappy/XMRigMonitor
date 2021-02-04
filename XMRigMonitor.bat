@echo off
setlocal EnableExtensions
setlocal EnableDelayedExpansion
set EXE=xmrig.exe
set PulseTime=10
set WorkingPath=C:\Users\Ryan\Desktop\xmrig-6.7.0
set CurrentDate=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%
set XMRigCrashCount=%WorkingPath%\backend\temp\XMRigCrashCount_%CurrentDate%.txt
set SystemCrashCount=%WorkingPath%\backend\temp\SystemCrashCount_%CurrentDate%.txt
set DailyLog=%WorkingPath%\backend\logs\Script_Log_%CurrentDate%.txt
set CPUTempPath=%WorkingPath%\backend\OpenHardwareMonitorReport

:STARTUP
if %username% == Ryan (echo [%date% %time%] Script Started Manually >> %DailyLog%) else (goto SYSTEM_CRASH)
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% echo [%date% %time%] XMRig already running, script monitoring... >> %DailyLog% && goto PULSE
start %WorkingPath%\xmrig.exe
echo [%date% %time%] Initial XMRig Triggered, script monitoring... >> %DailyLog%

:PULSE
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto FOUND
start %WorkingPath%\xmrig.exe
for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto XMRIG_CRASH
goto PULSE

:FOUND
start %CPUTempPath%\OpenHardwareMonitorReport.exe ReportToFile -f %CPUTempPath%\temp\pull.txt --IgnoreMonitorGPU --IgnoreMonitorHDD --IgnoreMonitorRAM --IgnoreMonitorFanController
for /f "tokens=2 delims=:" %%a in ('type %CPUTempPath%\temp\pull.txt^|find "/amdcpu/0/temperature/0"') do (
  echo %%a > %CPUTempPath%\temp\pulled.txt
)
for /f "tokens=3" %%a in (%CPUTempPath%\temp\pulled.txt) do set PulledTemp=%%a && echo [%date% %time%] Last CPU Temp: %PulledTemp%C > %CPUTempPath%\temp\lasttemp.txt
del %CPUTempPath%\temp\pull.txt && del %CPUTempPath%\temp\pulled.txt
cls && echo [%date% %time%] Still running...
timeout /t %PulseTime% > nul
goto PULSE

:XMRIG_CRASH
if not exist %XMRigCrashCount% del /F /Q %WorkingPath%\backend\temp\*.* & >%XMRigCrashCount% echo 0
for /f " delims==" %%i in (%XMRigCrashCount%) do set /A TempCounter= %%i+1 
if %TempCounter% geq 0 echo %TempCounter% > %XMRigCrashCount%
echo [%date% %time%] XMRig Crash Recovered %TempCounter% times today, script monitoring... >> %DailyLog%
type %CPUTempPath%\temp\lasttemp.txt >> %DailyLog%
call %WorkingPath%\backend\Crash.bat 1
goto PULSE

:SYSTEM_CRASH
if not exist %SystemCrashCount% del %WorkingPath%\backend\temp\*.* & >%SystemCrashCount% echo 0
for /f " delims==" %%i in (%SystemCrashCount%) do set /A TempCounter= %%i+1 
if %TempCounter% geq 0 echo %TempCounter% > %XMRigCrashCount%
echo [%date% %time%] System Crashed %TempCounter% times today, checking network... >> %DailyLog%
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
    start %WorkingPath%\xmrig.exe
    for /F %%x in ('tasklist /NH /FI "IMAGENAME eq %EXE%"') do if %%x == %EXE% goto SUCCESS
	)
	
:SUCCESS
echo [%date% %time%] XMRig Running, script monitoring... >> %DailyLog%
type %CPUTempPath%\temp\lasttemp.txt >> %DailyLog%
call %WorkingPath%\backend\Crash.bat 2
goto PULSE