@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo =============================================
echo       ConnectVertix - Flutter Web
echo =============================================
where flutter >nul 2>nul
if errorlevel 1 (
  echo.
  echo ERRO: Flutter nao foi encontrado neste computador.
  echo Instale o Flutter e adicione a pasta flutter\bin ao PATH.
  echo Guia oficial: https://docs.flutter.dev/get-started/install/windows/web
  echo Depois feche e reabra este terminal.
  pause
  exit /b 1
)
flutter pub get
if errorlevel 1 (
  echo Erro ao baixar as dependencias.
  pause
  exit /b 1
)
flutter run -d chrome --web-port=8080
pause
