@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\local-preview.ps1" -Action stop
if errorlevel 1 (
  echo.
  echo Failed to stop the local preview. See the error above.
  pause
  exit /b 1
)
endlocal
