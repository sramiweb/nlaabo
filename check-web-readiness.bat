@echo off
echo ========================================
echo Nlaabo Web Deployment Readiness Check
echo ========================================

set "ERRORS=0"
set "WARNINGS=0"

echo.
echo Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed or not in PATH
    set /a ERRORS+=1
) else (
    echo ✅ Flutter is installed
)

echo.
echo Checking Vercel CLI...
vercel --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Vercel CLI is not installed
    echo    Install with: npm i -g vercel
    set /a WARNINGS+=1
) else (
    echo ✅ Vercel CLI is installed
)

echo.
echo Checking required files...

if exist "pubspec.yaml" (
    echo ✅ pubspec.yaml found
) else (
    echo ❌ pubspec.yaml not found
    set /a ERRORS+=1
)

if exist "vercel.json" (
    echo ✅ vercel.json found
) else (
    echo ❌ vercel.json not found
    set /a ERRORS+=1
)

if exist "web\index.html" (
    echo ✅ web/index.html found
) else (
    echo ❌ web/index.html not found
    set /a ERRORS+=1
)

if exist "web\manifest.json" (
    echo ✅ web/manifest.json found
) else (
    echo ❌ web/manifest.json not found
    set /a ERRORS+=1
)

if exist ".env" (
    echo ✅ .env file found
) else (
    echo ⚠️  .env file not found (will use Vercel env vars)
    set /a WARNINGS+=1
)

echo.
echo Checking environment variables...

if defined SUPABASE_URL (
    echo ✅ SUPABASE_URL is set
) else (
    echo ⚠️  SUPABASE_URL not set (ensure it's set in Vercel)
    set /a WARNINGS+=1
)

if defined SUPABASE_ANON_KEY (
    echo ✅ SUPABASE_ANON_KEY is set
) else (
    echo ⚠️  SUPABASE_ANON_KEY not set (ensure it's set in Vercel)
    set /a WARNINGS+=1
)

echo.
echo Checking dependencies...
if exist "pubspec.lock" (
    echo ✅ Dependencies are resolved
) else (
    echo ⚠️  Dependencies not resolved - run 'flutter pub get'
    set /a WARNINGS+=1
)

echo.
echo Testing build process...
echo Running: flutter build web --release --web-renderer canvaskit
flutter build web --release --web-renderer canvaskit >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ Web build successful
) else (
    echo ❌ Web build failed
    echo    Run 'flutter build web --release --web-renderer canvaskit' to see errors
    set /a ERRORS+=1
)

echo.
echo Checking build output...
if exist "build\web\index.html" (
    echo ✅ Build output exists
) else (
    echo ❌ Build output not found
    set /a ERRORS+=1
)

if exist "build\web\flutter_service_worker.js" (
    echo ✅ Service worker generated
) else (
    echo ⚠️  Service worker not found
    set /a WARNINGS+=1
)

echo.
echo ========================================
echo Readiness Check Results
echo ========================================

if %ERRORS% equ 0 (
    if %WARNINGS% equ 0 (
        echo 🎉 READY FOR DEPLOYMENT!
        echo    No errors or warnings found.
        echo.
        echo Next steps:
        echo 1. Run: deploy-vercel.bat
        echo 2. Set environment variables in Vercel dashboard
        echo 3. Test your deployment
    ) else (
        echo ⚠️  READY WITH WARNINGS
        echo    Found %WARNINGS% warning(s) - review above
        echo.
        echo You can proceed with deployment, but address warnings for best results.
    )
) else (
    echo ❌ NOT READY FOR DEPLOYMENT
    echo    Found %ERRORS% error(s) - fix these before deploying
    echo.
    echo Fix the errors above and run this check again.
)

echo.
echo Deployment checklist:
echo [ ] Environment variables set in Vercel
echo [ ] Custom domain configured (optional)
echo [ ] SSL certificate active
echo [ ] Test authentication flow
echo [ ] Verify responsive design
echo [ ] Check PWA installation

echo.
pause