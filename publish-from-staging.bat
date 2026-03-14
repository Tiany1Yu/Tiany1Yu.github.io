@echo off
setlocal

cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\publish-from-staging.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if not "%EXIT_CODE%"=="0" (
  echo [ERROR] Auto publish failed. Exit code: %EXIT_CODE%
) else (
  echo [OK] Auto publish finished.
)

pause
exit /b %EXIT_CODE%
