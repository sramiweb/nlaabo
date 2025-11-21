@echo off
echo ========================================
echo Deploying Nlaabo to Vercel
echo ========================================

REM Check if Vercel CLI is installed
vercel --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Vercel CLI is not installed
    echo Please install it with: npm i -g vercel
    echo Or download from: https://vercel.com/cli
    pause
    exit /b 1
)

echo.
echo Step 1: Building for production...
call build-web.bat
if %errorlevel% neq 0 (
    echo Build failed! Aborting deployment.
    pause
    exit /b 1
)

echo.
echo Step 2: Deploying to Vercel...
echo.
echo IMPORTANT: Make sure to set these environment variables in Vercel:
echo - SUPABASE_URL: %SUPABASE_URL%
echo - SUPABASE_ANON_KEY: [Your Supabase Anon Key]
echo.
echo Press any key to continue with deployment...
pause >nul

REM Deploy to Vercel
vercel --prod

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Deployment completed successfully!
    echo ========================================
    echo.
    echo Your app should be live at your Vercel domain.
    echo.
    echo Post-deployment checklist:
    echo 1. Test all major features
    echo 2. Check responsive design on different devices
    echo 3. Verify Supabase connection
    echo 4. Test authentication flow
    echo 5. Check PWA installation
    echo.
) else (
    echo.
    echo ERROR: Deployment failed!
    echo Please check the error messages above.
)

pause