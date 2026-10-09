@echo off
setlocal
cd /d "%~dp0"
set "EXTRA="
if /i "%~1"=="--no-browser" set "EXTRA=-NoBrowser"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\local-preview.ps1" -Action start %EXTRA%
if errorlevel 1 (
  echo.
  echo Failed to launch the local Astro blog. See the error above.
  if not "%~1"=="--no-browser" pause
  exit /b 1
)
endlocal
