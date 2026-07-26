#!/usr/bin/env pwsh
# Builds the MinePOS Windows release bundle with the Dart Shelf server
# compiled and bundled alongside the app, so the "Local (this device)"
# hosting flow (Create Shop wizard, Welcome screen's "Open Register") can
# auto-launch it instead of requiring a manually-started `dart run`.
#
# Run from the `pos/` directory: pwsh tool/build_windows_release.ps1
#
# Output: build/windows/x64/runner/Release/, with the server executable at
# .../Release/server/minepos_server.exe (LocalServerLauncher looks for it
# there via a path relative to Platform.resolvedExecutable).

$ErrorActionPreference = 'Stop'

$posDir = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $posDir
$serverDir = Join-Path $repoRoot 'server'

Write-Host '== Compiling server ==' -ForegroundColor Cyan
Push-Location $serverDir
try {
    dart pub get
    dart compile exe bin/server.dart -o minepos_server.exe
} finally {
    Pop-Location
}

Write-Host '== Building Flutter Windows release ==' -ForegroundColor Cyan
Push-Location $posDir
try {
    flutter build windows --release
} finally {
    Pop-Location
}

$releaseDir = Join-Path $posDir 'build\windows\x64\runner\Release'
$serverDestDir = Join-Path $releaseDir 'server'
New-Item -ItemType Directory -Force -Path $serverDestDir | Out-Null
Copy-Item (Join-Path $serverDir 'minepos_server.exe') $serverDestDir -Force
Remove-Item (Join-Path $serverDir 'minepos_server.exe') -Force

# The main app links sqlite3.dll via sqlite3_flutter_libs, which `flutter
# build windows` already compiles and drops next to the app exe. The bundled
# server.exe is a separate process needing its own copy in its own directory
# (Windows DLL search order checks the exe's own dir first, not siblings).
$sqliteDll = Join-Path $releaseDir 'sqlite3.dll'
if (-not (Test-Path $sqliteDll)) {
    throw "sqlite3.dll not found at $sqliteDll - flutter build windows should have produced it"
}
Copy-Item $sqliteDll $serverDestDir -Force

Write-Host '== Zipping release bundle ==' -ForegroundColor Cyan
$zipPath = Join-Path $posDir 'build\MinePOS-Windows.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $zipPath

Write-Host "== Done: $releaseDir ==" -ForegroundColor Green
Write-Host "== Bundle zip: $zipPath ==" -ForegroundColor Green
