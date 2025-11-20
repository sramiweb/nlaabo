@echo off
echo ========================================
echo   Building Nlaabo APK
echo ========================================
echo.

cd /d "%~dp0"

REM Check if keystore exists
if not exist "android\nlaabo-release-key.jks" (
    echo [1/4] Generating keystore...
    cd android
    keytool -genkey -v -keystore nlaabo-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias nlaabo -dname "CN=Nlaabo, OU=Nlaabo, O=Nlaabo, L=Casablanca, S=Casablanca, C=MA" -storepass nlaabo2024 -keypass nlaabo2024
    cd ..
    echo Keystore created!
) else (
    echo [1/4] Keystore exists, skipping...
)

REM Create key.properties if it doesn't exist
if not exist "android\key.properties" (
    echo [2/4] Creating key.properties...
    (
        echo storePassword=nlaabo2024
        echo keyPassword=nlaabo2024
        echo keyAlias=nlaabo
        echo storeFile=nlaabo-release-key.jks
    ) > android\key.properties
    echo key.properties created!
) else (
    echo [2/4] key.properties exists, skipping...
)

echo.
echo [3/4] Cleaning project...
call flutter clean
call flutter pub get

echo.
echo [4/4] Building APK...
call flutter build apk --release

echo.
echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo APK Location:
echo %cd%\build\app\outputs\flutter-apk\app-release.apk
echo.
echo To install on phone:
echo   adb install build\app\outputs\flutter-apk\app-release.apk
echo.
pause
