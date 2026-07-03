@echo off
setlocal
cd /d "%~dp0"

if not exist "build\app\outputs\symbols" mkdir "build\app\outputs\symbols"

flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols %*

exit /b %ERRORLEVEL%
