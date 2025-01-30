@echo off
echo This PS-Script clears all the EventLogs. 
echo.
echo Prerequisites are:
echo.
echo In SysWOW64 Powershell type: "Set-ExecutionPolicy Unrestricted"
echo (SysWOW64 Powershell = Windows PowerShell (x86))
echo Then copy the "clr-evt.ps1" Script file to the path:
echo C:\Windows\SysWOW64\WindowsPowerShell\v1.0\
echo.
echo *** Ready to execute script ***
echo.
echo Clearing all Event Logs
%SystemRoot%\SysWOW64\WindowsPowerShell\v1.0\powershell.exe clr-evt.ps1
pause