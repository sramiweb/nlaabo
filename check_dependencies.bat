@echo off
echo Checking for outdated dependencies...
echo.
flutter pub outdated
echo.
echo To update dependencies, run:
echo   flutter pub upgrade --major-versions
echo.
pause
