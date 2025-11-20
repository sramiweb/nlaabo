# Fix remaining issues - unused imports, dead code, and minor issues

Write-Host "Fixing remaining issues..." -ForegroundColor Cyan

# Remove specific unused imports
$filesToFix = @{
    "lib\design_system\colors\app_colors.dart" = @("app_colors_theme.dart")
    "lib\design_system\components\navigation\mobile_bottom_nav.dart" = @()
    "lib\design_system\components\navigation\navigation_responsive_wrapper.dart" = @("package:provider/provider.dart", "../../../providers/navigation_provider.dart")
    "lib\design_system\themes\theme_provider.dart" = @("../colors/app_colors.dart")
    "lib\main.dart" = @("package:nlaabo/design_system/themes/app_theme.dart")
    "lib\screens\admin_dashboard_screen.dart" = @("../utils/color_extensions.dart")
    "lib\screens\create_match_screen.dart" = @("../widgets/responsive_button.dart", "../utils/design_system.dart")
    "lib\screens\create_team_screen.dart" = @("../widgets/responsive_form_field.dart", "../widgets/responsive_button.dart", "../widgets/image_picker_widget.dart")
    "lib\screens\edit_profile_screen.dart" = @("../utils/color_extensions.dart")
    "lib\screens\forgot_password_screen.dart" = @("../widgets/loading_overlay.dart", "../constants/form_constants.dart")
    "lib\screens\match_details_screen.dart" = @("../design_system/spacing/app_spacing.dart", "../widgets/enhanced_empty_state.dart", "../widgets/enhanced_form_field.dart")
    "lib\screens\team_management_screen.dart" = @("../widgets/enhanced_empty_state.dart", "../widgets/enhanced_form_field.dart")
    "lib\screens\teams_screen.dart" = @("../widgets/cached_image.dart", "../design_system/spacing/app_spacing.dart")
    "lib\widgets\animations.dart" = @("../utils/design_system.dart")
    "lib\widgets\responsive_button.dart" = @("animations.dart")
    "lib\widgets\team_card.dart" = @("../design_system/spacing/app_spacing.dart")
    "test\accessibility_test.dart" = @("package:nlaabo/main.dart")
    "test\visual_regression_test.dart" = @("package:nlaabo/main.dart")
    "test_fixes.dart" = @("package:flutter/material.dart")
}

$modifiedCount = 0

foreach ($file in $filesToFix.Keys) {
    $fullPath = Join-Path $PWD $file
    if (Test-Path $fullPath) {
        $content = Get-Content $fullPath -Raw
        $originalContent = $content
        
        foreach ($import in $filesToFix[$file]) {
            # Remove the import line
            if ($import.StartsWith("package:")) {
                $content = $content -replace "import '$import';`r?`n", ""
            } else {
                $content = $content -replace "import '$import';`r?`n", ""
                $content = $content -replace "import `"$import`";`r?`n", ""
            }
        }
        
        if ($content -ne $originalContent) {
            Set-Content -Path $fullPath -Value $content -NoNewline
            $modifiedCount++
            Write-Host "Fixed: $file" -ForegroundColor Green
        }
    }
}

Write-Host "`nRemoved unused imports from $modifiedCount files" -ForegroundColor Yellow

# Fix dead code patterns
Write-Host "`nFixing dead code patterns..." -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "lib","test" -Filter "*.dart" -Recurse -ErrorAction SilentlyContinue

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Fix dead null-aware expressions
    $content = $content -replace '(\w+)\s*\?\?\s*\[\]', '$1'
    $content = $content -replace '(\w+)\s*\?\?\s*""', '$1'
    $content = $content -replace '(\w+)\s*\?\?\s*0', '$1'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "Fixed dead code in: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "`nCompleted!" -ForegroundColor Green
Write-Host "`nRunning flutter analyze..." -ForegroundColor Cyan
flutter analyze 2>&1 | Select-String "issues found"
