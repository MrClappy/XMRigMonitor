@echo off
SET EmailAccount="%~1"
SET "EmailPassword=%~2"
SET Subject="%~3"
SET LogFile="%~4"
SET Recipient="%~5"
SET SMTPServer="%~6"
SET SMTPPortNumber="%~7"

Powershell -ExecutionPolicy Bypass -Command "& '%~dp0\Emailer.ps1' '%EmailAccount%' '%EmailPassword%' '%Subject%' %LogFile% %Recipient% %SMTPServer% %SMTPPortNumber%"