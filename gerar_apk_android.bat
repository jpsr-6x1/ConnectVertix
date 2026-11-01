@echo off
chcp 65001 >nul
cd /d "%~dp0"
if not exist "supabase\config.dev.json" (
  echo Configure primeiro supabase\config.dev.json - veja CONFIGURACAO_SUPABASE.md
  pause
  exit /b 1
)
where flutter >nul 2>nul
if errorlevel 1 (echo Flutter nao encontrado no PATH.&pause&exit /b 1)
powershell -NoProfile -ExecutionPolicy Bypass -File "preparar_android.ps1"
if errorlevel 1 goto :erro
flutter pub get
if errorlevel 1 goto :erro
flutter build apk --release --dart-define-from-file=supabase/config.dev.json
if errorlevel 1 goto :erro
echo.
echo APK GERADO: %cd%\build\app\outputs\flutter-apk\app-release.apk
explorer "build\app\outputs\flutter-apk"
pause
exit /b 0
:erro
echo Falha ao gerar APK. Leia a mensagem acima.
pause
exit /b 1
