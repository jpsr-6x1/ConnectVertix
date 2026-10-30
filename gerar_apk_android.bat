@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo =============================================
echo     ConnectVertix - Gerar APK Android
 echo =============================================
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter nao encontrado. Configure a pasta flutter\bin no PATH.
  pause
  exit /b 1
)
flutter create --platforms=android .
if errorlevel 1 goto :erro
flutter pub get
if errorlevel 1 goto :erro
flutter build apk --release
if errorlevel 1 goto :erro
echo.
echo APK gerado em:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
explorer "build\app\outputs\flutter-apk"
pause
exit /b 0
:erro
echo.
echo Nao foi possivel gerar o APK.
echo Se surgir erro NDK 28.2.13676358, instale essa versao pelo SDK Manager do Android Studio.
pause
exit /b 1
