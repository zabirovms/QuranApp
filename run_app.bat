@echo off
echo Flutter Quran App - Build Script
echo ================================

echo.
echo 1. Cleaning project...
call C:\src\flutter\bin\flutter clean

echo.
echo 2. Getting dependencies...
call C:\src\flutter\bin\flutter pub get

echo.
echo 3. Running app...
call C:\src\flutter\bin\flutter run

echo.
echo Done! Press any key to exit.
pause
