@echo off
cd /d "%~dp0"

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    echo Port 8080 is already in use - a server is likely already running.
    echo Check Task Manager for dart.exe/dartvm.exe if this is unexpected.
    pause
    exit /b 1
)

dart run bin/server.dart
pause
