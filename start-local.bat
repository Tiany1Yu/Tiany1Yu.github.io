@echo off
setlocal

REM Always run from repo root, even when double-clicked.
cd /d "%~dp0"

set "HOST=127.0.0.1"
set "PORT=4000"

where bundle >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Bundler not found. Please install Ruby + Bundler first.
  echo         https://www.ruby-lang.org/
  pause
  exit /b 1
)

echo [1/2] Installing/validating gems...
call bundle install
if errorlevel 1 (
  echo [ERROR] bundle install failed.
  pause
  exit /b 1
)

echo [2/2] Starting Jekyll server at http://%HOST%:%PORT%
start "" "http://%HOST%:%PORT%"
call bundle exec jekyll serve --livereload --host %HOST% --port %PORT%

endlocal
