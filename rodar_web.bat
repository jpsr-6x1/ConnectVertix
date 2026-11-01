@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "supabase\config.dev.json" (
  echo Configure supabase\config.dev.json. Veja CONFIGURACAO_SUPABASE.md
  pause
  exit /b 1
)
flutter pub get
if errorlevel 1 (pause&exit /b 1)
flutter run -d chrome --web-port=8080 --dart-define-from-file=supabase/config.dev.json
pause
