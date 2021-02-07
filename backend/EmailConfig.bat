@echo off
SET "CrashType=%~1"
SET EmailAccount="%~2"
SET "EmailPassword=%~3"
SET Subject="%~4"
SET LogFile="%~5"
SET Recipient="%~6"
SET SMTPServer="%~7"
SET SMTPPortNumber="%~8"

REM Uncomment to send email when XMRig app crashes
if "%CrashType%" == "1" (
    Powershell -ExecutionPolicy Bypass -Command "& '%~dp0\Emailer.ps1' '%EmailAccount%' '%EmailPassword%' '%Subject%' %LogFile% %Recipient% %SMTPServer% %SMTPPortNumber%"
) 

if "%CrashType%" == "2" (
    Powershell -ExecutionPolicy Bypass -Command "& '%~dp0\Emailer.ps1' '%EmailAccount%' '%EmailPassword%' '%Subject%' %LogFile% %Recipient% %SMTPServer% %SMTPPortNumber%"
)

