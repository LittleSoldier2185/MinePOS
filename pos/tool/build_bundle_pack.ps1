#!/usr/bin/env pwsh
# Runs the full release pipeline (build_release_pack.ps1) then repackages
# its three outputs - Windows app+bundled server, standalone server, and
# Android APK - into one combined zip for a single-download distribution.
#
# Run from the `pos/` directory: pwsh tool/build_bundle_pack.ps1
#
# Output: pos/build/MinePOS-bundle-pack.zip

$ErrorActionPreference = 'Stop'
$posDir = $PSScriptRoot | Split-Path -Parent
$buildDir = Join-Path $posDir 'build'

& (Join-Path $PSScriptRoot 'build_release_pack.ps1')

Write-Host '== Combining into MinePOS-bundle-pack.zip ==' -ForegroundColor Cyan

$windowsZip = Join-Path $buildDir 'MinePOS-Windows.zip'
$serverZip = Join-Path $buildDir 'MinePOS-Server-Windows.zip'
$apk = Join-Path $buildDir 'MinePOS-Android.apk'
foreach ($p in @($windowsZip, $serverZip, $apk)) {
    if (-not (Test-Path $p)) { throw "Expected release output missing: $p" }
}

$stage = Join-Path $buildDir '.bundle-pack-stage'
if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'windows-app') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stage 'standalone-server') | Out-Null

Expand-Archive -Path $windowsZip -DestinationPath (Join-Path $stage 'windows-app') -Force
Expand-Archive -Path $serverZip -DestinationPath (Join-Path $stage 'standalone-server') -Force
Copy-Item $apk (Join-Path $stage 'MinePOS-Android.apk') -Force

$bundlePath = Join-Path $buildDir 'MinePOS-bundle-pack.zip'
if (Test-Path $bundlePath) { Remove-Item $bundlePath -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $bundlePath
Remove-Item $stage -Recurse -Force

Write-Host "== Done: $bundlePath ==" -ForegroundColor Green
