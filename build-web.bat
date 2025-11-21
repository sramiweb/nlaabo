@echo off
echo ========================================
echo Building Nlaabo for Web (Vercel)
echo ========================================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter and add it to your PATH
    pause
    exit /b 1
)

echo.
echo Step 1: Cleaning previous builds...
flutter clean

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building for web (optimized for Vercel)...
flutter build web --release ^
    --web-renderer canvaskit ^
    --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://unpkg.com/canvaskit-wasm@0.38.0/bin/ ^
    --dart-define=FLUTTER_WEB=true ^
    --source-maps ^
    --tree-shake-icons

if %errorlevel% neq 0 (
    echo.
    echo ERROR: Web build failed!
    echo Please check the error messages above.
    pause
    exit /b 1
)

echo.
echo Step 4: Optimizing build output...

REM Copy optimized service worker
if exist "web\sw.js" (
    copy "web\sw.js" "build\web\sw.js" >nul
    echo - Service worker copied
)

REM Create .nojekyll file for GitHub Pages compatibility
echo. > "build\web\.nojekyll"
echo - Created .nojekyll file

REM Copy environment file to build directory
if exist ".env" (
    copy ".env" "build\web\assets\.env" >nul
    echo - Environment file copied to assets
)

echo.
echo ========================================
echo Web build completed successfully!
echo ========================================
echo.
echo Build output: build\web\
echo.
echo Next steps:
echo 1. Deploy to Vercel: vercel --prod
echo 2. Or test locally: cd build\web ^&^& python -m http.server 8000
echo.
echo Environment variables to set in Vercel:
echo - SUPABASE_URL
echo - SUPABASE_ANON_KEY
echo.
pause