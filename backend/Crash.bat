@echo off
SET GmailAccount="xxx"
SET "GmailPassword=xxx"
SET PowerShellDir=C:\Windows\System32\WindowsPowerShell\v1.0
CD /D "%PowerShellDir%"
SET "param1=%~1"

REM Uncomment to send email when XMRig app crashes
REM if "%param1%" == "1" (
REM     Powershell -ExecutionPolicy Bypass -Command "& 'C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Email.ps1' '%GmailAccount%' '%GmailPassword%' 'XMRig Crashed on PAC :('"
REM ) 

if "%param1%" == "2" (
    Powershell -ExecutionPolicy Bypass -Command "& 'C:\Users\Ryan\Desktop\xmrig-6.7.0\backend\Email.ps1' '%GmailAccount%' '%GmailPassword%' 'PAC Crashed :('"
)