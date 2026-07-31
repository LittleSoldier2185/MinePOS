#!/usr/bin/env pwsh
# Builds the full MinePOS distributable set: the Windows desktop app (with
# the server bundled in for self-hosting), a standalone headless server
# package (for a dedicated host machine with no GUI), and the Android APK.
#
# Run from the `pos/` directory: pwsh tool/build_release_pack.ps1
#
# Output (all in pos/build/):
#   MinePOS-Windows.zip        - desktop app + bundled server
#   MinePOS-Server-Windows.zip - standalone server only (minepos_server.exe)
#   MinePOS-Android.apk        - Android release build

$ErrorActionPreference = 'Stop'
$posDir = $PSScriptRoot | Split-Path -Parent
$buildDir = Join-Path $posDir 'build'

Write-Host '== Step 1/3: Windows app + bundled server ==' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'build_windows_release.ps1')

Write-Host '== Step 2/3: Standalone server package ==' -ForegroundColor Cyan
$releaseServerDir = Join-Path $posDir 'build\windows\x64\runner\Release\server'
$exePath = Join-Path $releaseServerDir 'minepos_server.exe'
$dllPath = Join-Path $releaseServerDir 'sqlite3.dll'
if (-not (Test-Path $exePath) -or -not (Test-Path $dllPath)) {
    throw "Expected $exePath and $dllPath from the Windows build - build_windows_release.ps1 may have changed its output layout."
}
$standaloneStage = Join-Path $buildDir '.standalone-server-stage'
if (Test-Path $standaloneStage) { Remove-Item $standaloneStage -Recurse -Force }
New-Item -ItemType Directory -Force -Path $standaloneStage | Out-Null
Copy-Item $exePath $standaloneStage -Force
Copy-Item $dllPath $standaloneStage -Force

# A launcher matching server/run_server.bat's port-check, but running the
# compiled exe directly instead of `dart run` (no Dart SDK on a headless
# host machine).
@'
@echo off
cd /d "%~dp0"

powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue) { exit 1 } else { exit 0 }"
if errorlevel 1 (
    echo Port 8080 is already in use - a server is likely already running.
    pause
    exit /b 1
)

minepos_server.exe
pause
'@ | Set-Content -Path (Join-Path $standaloneStage 'run_server.bat') -Encoding ascii

$serverZipPath = Join-Path $buildDir 'MinePOS-Server-Windows.zip'
if (Test-Path $serverZipPath) { Remove-Item $serverZipPath -Force }
Compress-Archive -Path (Join-Path $standaloneStage '*') -DestinationPath $serverZipPath
Remove-Item $standaloneStage -Recurse -Force

Write-Host '== Step 3/3: Android APK ==' -ForegroundColor Cyan
Push-Location $posDir
try {
    flutter build apk --release
} finally {
    Pop-Location
}
$apkSrc = Join-Path $posDir 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apkSrc)) { throw "Expected APK not found at $apkSrc" }
$apkDest = Join-Path $buildDir 'MinePOS-Android.apk'
Copy-Item $apkSrc $apkDest -Force

Write-Host '== Done ==' -ForegroundColor Green
Write-Host " Windows app:      $(Join-Path $buildDir 'MinePOS-Windows.zip')" -ForegroundColor Green
Write-Host " Standalone server: $serverZipPath" -ForegroundColor Green
Write-Host " Android APK:       $apkDest" -ForegroundColor Green
