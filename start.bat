@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"
set "PAPERCLIP_DEV_URL=http://127.0.0.1:3100/"
title Paperclip Dev

powershell -NoLogo -NoProfile -Command ^
  "$id = [Security.Principal.WindowsIdentity]::GetCurrent();" ^
  "$principal = New-Object Security.Principal.WindowsPrincipal($id);" ^
  "if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% EQU 0 (
  echo start.bat cannot run from an Administrator console.
  echo Embedded PostgreSQL refuses to start with administrative privileges.
  echo Run start.bat from a normal non-admin Command Prompt, PowerShell, or Explorer.
  pause
  endlocal & exit /b 1
)

powershell -NoLogo -NoProfile -Command ^
  "try { $resp = Invoke-WebRequest -UseBasicParsing ($env:PAPERCLIP_DEV_URL + 'api/health') -TimeoutSec 2; if ($resp.StatusCode -eq 200) { exit 0 } } catch {} exit 1"
if %ERRORLEVEL% EQU 0 (
  echo Paperclip dev server is already running.
  start "" "%PAPERCLIP_DEV_URL%"
  pause
  endlocal & exit /b 0
)

call paperclip-dev.cmd

set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
