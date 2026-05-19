@echo off
setlocal EnableExtensions

for %%I in ("%~dp0.") do set "REPO_ROOT=%%~fI"
set "SCRIPT_PATH=%REPO_ROOT%\scripts\publish-from-staging.ps1"

if not exist "%SCRIPT_PATH%" (
  echo [ERROR] Script not found: "%SCRIPT_PATH%"
  pause
  exit /b 1
)

pushd "%REPO_ROOT%" >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -RepoRoot "%REPO_ROOT%" %*
set "EXIT_CODE=%ERRORLEVEL%"
popd >nul

echo.
if not "%EXIT_CODE%"=="0" (
  echo [ERROR] Auto publish failed. Exit code: %EXIT_CODE%
) else (
  echo [OK] Auto publish finished.
)

pause
exit /b %EXIT_CODE%
