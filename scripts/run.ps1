# Roda o app (Windows). Usa Flutter em .tools/flutter se existir.
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

$flutter = if (Test-Path ".\.tools\flutter\bin\flutter.bat") {
  ".\.tools\flutter\bin\flutter.bat"
} elseif (Get-Command flutter -ErrorAction SilentlyContinue) {
  "flutter"
} else {
  Write-Host "Flutter não encontrado. Instale o SDK ou clone em .tools/flutter (ver SETUP.md)." -ForegroundColor Red
  exit 1
}

& $flutter pub get
& $flutter run -d windows @args
