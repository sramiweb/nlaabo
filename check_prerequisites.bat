@echo off
echo Checking MCP Prerequisites...
echo =============================
echo.

echo Checking Node.js:
node --version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Node.js is installed
    node --version
) else (
    echo [ERROR] Node.js is NOT installed
)

echo.
echo Checking NPM:
npm --version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] NPM is installed
    npm --version
) else (
    echo [ERROR] NPM is NOT installed
)

echo.
echo Checking Python:
python --version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Python is installed
    python --version
) else (
    echo [ERROR] Python is NOT installed
)

echo.
echo Checking Dart:
dart --version >nul 2>&1
if %errorlevel%==0 (
    echo [OK] Dart is installed
    dart --version
) else (
    echo [ERROR] Dart is NOT installed
)

echo.
echo =============================
echo Prerequisites check complete
echo =============================