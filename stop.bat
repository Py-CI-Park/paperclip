@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"
set "REPO_ROOT=%CD%"
set "PAPERCLIP_DEV_PORT=3100"

set "PAPERCLIP_HOME=%ROOT%.paperclip-local"
set "PID_FILE=%PAPERCLIP_HOME%\stop-pids.txt"
set "PATH=%ROOT%;%PATH%"

powershell -NoLogo -NoProfile -Command ^
  "$runtime = Join-Path $env:PAPERCLIP_HOME 'instances\\default\\runtime-services';" ^
  "$repo = (Resolve-Path '.').Path;" ^
  "$pids = @();" ^
  "if (Test-Path $runtime) {" ^
  "  Get-ChildItem $runtime -Filter *.json | ForEach-Object {" ^
  "    try { $record = Get-Content $_.FullName -Raw | ConvertFrom-Json } catch { return }" ^
  "    if ($record.profileKind -eq 'paperclip-dev' -and $record.metadata.repoRoot -eq $repo) {" ^
  "      if ($record.pid) { $pids += [int]$record.pid }" ^
  "      if ($record.metadata.childPid) { $pids += [int]$record.metadata.childPid }" ^
  "    }" ^
  "  }" ^
  "}" ^
  "$pids | Sort-Object -Unique | Set-Content -Path $env:PID_FILE"

call corepack pnpm dev:stop %*

powershell -NoLogo -NoProfile -Command ^
  "if (Test-Path $env:PID_FILE) {" ^
  "  Get-Content $env:PID_FILE | ForEach-Object {" ^
  "    $targetPid = 0;" ^
  "    if ([int]::TryParse($_.Trim(), [ref]$targetPid) -and $targetPid -gt 0) {" ^
  "      Stop-Process -Id $targetPid -Force -ErrorAction SilentlyContinue" ^
  "    }" ^
  "  };" ^
  "  Remove-Item $env:PID_FILE -Force -ErrorAction SilentlyContinue" ^
  "}"

powershell -NoLogo -NoProfile -Command ^
  "$listener = Get-NetTCPConnection -LocalPort $env:PAPERCLIP_DEV_PORT -State Listen -ErrorAction SilentlyContinue | Select-Object -First 1;" ^
  "if ($listener) {" ^
  "  $proc = Get-CimInstance Win32_Process -Filter ('ProcessId = ' + $listener.OwningProcess) -ErrorAction SilentlyContinue;" ^
  "  if ($proc -and $proc.CommandLine -like ('*' + $env:REPO_ROOT + '*') -and $proc.CommandLine -like '*src/index.ts*') {" ^
  "    Stop-Process -Id $listener.OwningProcess -Force -ErrorAction SilentlyContinue" ^
  "  }" ^
  "}"

powershell -NoLogo -NoProfile -Command ^
  "$patterns = @('scripts/dev-runner.ts', 'scripts/dev-watch.ts', 'src/index.ts', 'paperclip-dev.cmd', 'launch-dev.cmd');" ^
  "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {" ^
  "  $commandLine = $_.CommandLine;" ^
  "  $commandLine -and $commandLine -like ('*' + $env:REPO_ROOT + '*') -and ($patterns | Where-Object { $commandLine -like ('*' + $_ + '*') })" ^
  "} | ForEach-Object {" ^
  "  Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue" ^
  "}"

powershell -NoLogo -NoProfile -Command ^
  "$launcherPatterns = @('paperclip-dev.cmd', 'launch-dev.cmd');" ^
  "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {" ^
  "  $commandLine = $_.CommandLine;" ^
  "  $commandLine -and ($launcherPatterns | Where-Object { $commandLine -like ('*' + $_ + '*') })" ^
  "} | ForEach-Object {" ^
  "  Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue" ^
  "}"

taskkill /F /T /FI "WINDOWTITLE eq Paperclip Dev" >nul 2>nul

del /f /q "%PAPERCLIP_HOME%\\bin\\launch-dev.cmd" >nul 2>nul

set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
