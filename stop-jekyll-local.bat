@echo off
setlocal

set "PORT=4000"
set "FOUND=0"

for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":%PORT% .*LISTENING"') do (
  set "FOUND=1"
  echo Stopping process %%p on port %PORT%...
  taskkill /PID %%p /F >nul 2>nul
)

if "%FOUND%"=="0" (
  echo No listening process found on port %PORT%.
) else (
  echo Done.
)

endlocal
