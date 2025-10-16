@echo off
echo Fixing Flutter Android project structure...

cd /d "%~dp0"

echo Creating proper Android project structure...

REM Create the gradle wrapper directory
if not exist "android\gradle\wrapper" mkdir "android\gradle\wrapper"

REM Copy gradle wrapper from Flutter SDK
echo Please run: flutter create . --project-name quran_app
echo This will regenerate the proper Android project files.

echo.
echo After running flutter create, the project should work properly.
echo.
pause
