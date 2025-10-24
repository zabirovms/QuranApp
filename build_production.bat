@echo off
echo Building Quran App for Production Release
echo ==========================================

echo.
echo This script will build production-ready files for your Quran app.
echo.

echo Step 1: Cleaning previous builds...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building Android APK (Release)...
flutter build apk --release

echo.
echo Step 4: Building Android App Bundle (Release)...
flutter build appbundle --release

echo.
echo Production builds completed!
echo.
echo Generated files:
echo - APK: build\app\outputs\apk\release\app-release.apk
echo - AAB: build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Test the APK on a device
echo 2. Upload AAB to Google Play Console
echo 3. Submit for review
echo.
pause
