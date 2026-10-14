# Validação do app Flutter (modo local v2)
$ErrorActionPreference = "Continue"
Write-Host "=== Transporte SCT — validate-dev (local) ===" -ForegroundColor Cyan

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host "[!!] Flutter não está no PATH. Instale o SDK e tente novamente." -ForegroundColor Yellow
  exit 1
}

Push-Location $PSScriptRoot\..
flutter pub get
flutter analyze
flutter test
Pop-Location

Write-Host "OK." -ForegroundColor Green
