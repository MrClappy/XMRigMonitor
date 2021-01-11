@echo off
SETLOCAL EnableExtensions
set EXE=xmrig.exe
set PULSETIME=10

if %username% == Ryan (echo [%date% %time%] Script Started Manually >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt) else (goto SYSTEM_CRASH)
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% echo [%date% %time%] XMRig already running, script monitoring... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt && goto PULSE
start C:\Users\Ryan\Desktop\xmrig-6.7.0\xmrig.exe
echo [%date% %time%] Initial XMRig Triggered, script monitoring... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt

:PULSE
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% goto FOUND
start C:\Users\Ryan\Desktop\xmrig-6.7.0\xmrig.exe
FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% goto XMRIG_CRASH
goto PULSE

:FOUND
cls && echo [%date% %time%] Still running...
timeout /t %PULSETIME% > nul
goto PULSE

:XMRIG_CRASH
echo [%date% %time%] XMRig Crash Recovered, script monitoring... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt
CALL C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Crash.bat 1
goto PULSE

:SYSTEM_CRASH
echo [%date% %time%] Script Triggered By System, Checking Network... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt
goto RECOVERY

:RECOVERY
ping -n 1 192.168.1.1 | find "TTL=" > nul
if errorlevel 1 (
    echo [%date% %time%] Network Still Down... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt
    timeout /t 1 > nul    
    goto RECOVERY
) else (
    echo [%date% %time%] Network Recovered >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt
    FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% goto PULSE
    start C:\Users\Ryan\Desktop\xmrig-6.7.0\xmrig.exe
    FOR /F %%x IN ('tasklist /NH /FI "IMAGENAME eq %EXE%"') DO IF %%x == %EXE% goto SUCCESS
)

:SUCCESS

echo [%date% %time%] XMRig Running, script monitoring... >> C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\logs\Script_log.txt
CALL C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Crash.bat 2
goto PULSE