@echo off
SET GmailAccount=""
SET "GmailPassword=""
SET PowerShellDir=C:\Windows\System32\WindowsPowerShell\v1.0
CD /D "%PowerShellDir%"
SET "param1=%~1"

if "%param1%" == "1" (
    Powershell -ExecutionPolicy Bypass -Command "& 'C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Email.ps1' '%GmailAccount%' '%GmailPassword%' 'xxx'"
) 
if "%param1%" == "2" (
    Powershell -ExecutionPolicy Bypass -Command "& 'C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Email.ps1' '%GmailAccount%' '%GmailPassword%' 'xxx'"
)

