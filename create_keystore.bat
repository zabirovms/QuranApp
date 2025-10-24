@echo off
echo Creating Android Production Keystore for Quran App
echo ==================================================

echo.
echo This script will create a production keystore for your Quran app.
echo You will need to provide:
echo - Keystore password
echo - Key password  
echo - Your name and organization details
echo.

echo Generating keystore...
keytool -genkey -v -keystore quran-app-release-key.keystore -alias quran-app-key -keyalg RSA -keysize 2048 -validity 10000

echo.
echo Keystore created successfully!
echo.
echo IMPORTANT SECURITY NOTES:
echo - Store the keystore file securely
echo - Remember your passwords
echo - Never commit the keystore to version control
echo - Keep backups of the keystore file
echo.
echo Next steps:
echo 1. Update android/app/build.gradle with your passwords
echo 2. Run: flutter build appbundle --release
echo 3. Upload the AAB file to Google Play Console
echo.
pause
