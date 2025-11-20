# Fix all remaining issues comprehensively

Write-Host "Fixing all remaining issues..." -ForegroundColor Cyan

# Fix remaining withOpacity deprecations
$withOpacityFiles = @(
    "lib\design_system\components\buttons\destructive_button.dart",
    "lib\design_system\components\buttons\primary_button.dart",
    "lib\design_system\components\buttons\secondary_button.dart",
    "lib\design_system\components\cards\base_card.dart",
    "lib\screens\forgot_password_confirmation_screen.dart",
    "lib\utils\color_extensions.dart",
    "lib\utils\design_system.dart"
)

foreach ($file in $withOpacityFiles) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        $content = $content -replace '\.withOpacity\s*\(\s*([0-9.]+)\s*\)', '.withValues(alpha: $1)'
        Set-Content -Path $fullPath -Value $content -NoNewline
        Write-Host "Fixed withOpacity in: $file" -ForegroundColor Green
    }
}

# Fix remaining AppColors deprecations in desktop_sidebar
$sidebarFile = "lib\design_system\components\navigation\desktop_sidebar.dart"
$fullPath = Join-Path $PWD $sidebarFile
if (Test-Path $fullPath) {
    $content = Get-Content $fullPath -Raw
    $content = $content -replace 'AppColors\.darkSurface', 'const Color(0xFF1F2937)'
    $content = $content -replace 'AppColors\.darkBorder', 'const Color(0xFF374151)'
    $content = $content -replace 'AppColors\.darkTextSubtle', 'const Color(0xFF9CA3AF)'
    Set-Content -Path $fullPath -Value $content -NoNewline
    Write-Host "Fixed AppColors in: $sidebarFile" -ForegroundColor Green
}

# Remove unused imports
$unusedImports = @{
    "lib\screens\profile_screen.dart" = @("package:flutter/foundation.dart")
    "lib\services\api_service.dart" = @("dart:typed_data")
    "tools\print_env_report.dart" = @("package:nlaabo/config/environment_validator.dart")
}

foreach ($file in $unusedImports.Keys) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        foreach ($import in $unusedImports[$file]) {
            $content = $content -replace "import '$import';`r?`n", ""
        }
        Set-Content -Path $fullPath -Value $content -NoNewline
        Write-Host "Removed unused imports from: $file" -ForegroundColor Green
    }
}

# Remove dead code in create_match_screen
$matchFile = "lib\screens\create_match_screen.dart"
$fullPath = Join-Path $PWD $matchFile
if (Test-Path $fullPath) {
    $content = Get-Content $fullPath -Raw
    # Remove ?? [] patterns
    $content = $content -replace '\s*\?\?\s*\[\]', ''
    Set-Content -Path $fullPath -Value $content -NoNewline
    Write-Host "Fixed dead code in: $matchFile" -ForegroundColor Green
}

# Remove dead code in team_preview_card
$cardFile = "lib\widgets\team_preview_card.dart"
$fullPath = Join-Path $PWD $cardFile
if (Test-Path $fullPath) {
    $content = Get-Content $fullPath -Raw
    $content = $content -replace '\s*\?\?\s*\[\]', ''
    Set-Content -Path $fullPath -Value $content -NoNewline
    Write-Host "Fixed dead code in: $cardFile" -ForegroundColor Green
}

# Remove dead code in test_rtl_support
$rtlFile = "test\test_rtl_support.dart"
$fullPath = Join-Path $PWD $rtlFile
if (Test-Path $fullPath) {
    $content = Get-Content $fullPath -Raw
    $content = $content -replace '\s*\?\?\s*\[\]', ''
    Set-Content -Path $fullPath -Value $content -NoNewline
    Write-Host "Fixed dead code in: $rtlFile" -ForegroundColor Green
}

Write-Host "`nCompleted!" -ForegroundColor Green
Write-Host "`nRunning flutter analyze..." -ForegroundColor Cyan
flutter analyze 2>&1 | Select-String "issues found"
