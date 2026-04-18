@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"
title Paperclip Dev

powershell -NoLogo -NoProfile -Command ^
  "$id = [Security.Principal.WindowsIdentity]::GetCurrent();" ^
  "$principal = New-Object Security.Principal.WindowsPrincipal($id);" ^
  "if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 0 } else { exit 1 }"
if %ERRORLEVEL% EQU 0 (
  echo This console is running as Administrator.
  echo Embedded PostgreSQL refuses to start with administrative privileges.
  echo Close this window and run start.bat from a normal non-admin shell.
  pause
  endlocal & exit /b 1
)

set "PAPERCLIP_HOME=%ROOT%.paperclip-local"
set "PATH=%ROOT%;%PATH%"
set "PAPERCLIP_UI_DEV_MIDDLEWARE=true"
set "PAPERCLIP_MIGRATION_AUTO_APPLY=true"
set "PAPERCLIP_MIGRATION_PROMPT=never"
set "PAPERCLIP_OPEN_ON_LISTEN=true"

echo Starting Paperclip dev server...
echo   UI: http://127.0.0.1:3100/
echo   API: http://127.0.0.1:3100/api
echo.

call pnpm --filter @paperclipai/plugin-sdk build
if errorlevel 1 (
  echo.
  echo Plugin SDK build failed.
  pause
  endlocal & exit /b 1
)

call pnpm --filter @paperclipai/server dev
set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo Paperclip dev server stopped or failed with exit code %EXIT_CODE%.
echo Press any key to close this window.
pause >nul

endlocal & exit /b %EXIT_CODE%
