# Comprehensive fix for all remaining issues

Write-Host "Fixing all remaining issues..." -ForegroundColor Cyan

# Get all Dart files
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

$totalFiles = $dartFiles.Count
$processedFiles = 0
$modifiedFiles = 0

foreach ($file in $dartFiles) {
    $processedFiles++
    Write-Progress -Activity "Processing files" -Status "$processedFiles of $totalFiles" -PercentComplete (($processedFiles / $totalFiles) * 100)
    
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Fix remaining withOpacity that were missed (with spaces or different patterns)
    $content = $content -replace '\.withOpacity\s*\(\s*([0-9.]+)\s*\)', '.withValues(alpha: $1)'
    
    # Fix context.colors references that need BuildContext import
    # Add import if context.colors is used but BuildContext extension is missing
    if ($content -match 'context\.colors\.' -and $content -notmatch "import.*app_colors_extensions") {
        if ($content -match "import 'package:flutter/material.dart';") {
            $content = $content -replace "(import 'package:flutter/material.dart';)", "`$1`nimport '../design_system/colors/app_colors_extensions.dart';"
        }
    }
    
    # Remove unused imports
    $lines = $content -split "`r?`n"
    $usedImports = @()
    $importLines = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^import\s+'([^']+)';") {
            $importPath = $matches[1]
            $importLines += @{Index = $i; Path = $importPath; Line = $lines[$i]}
        }
    }
    
    # Check which imports are actually used
    foreach ($import in $importLines) {
        $importName = $import.Path -replace '.*/([^/]+)\.dart$', '$1'
        $isUsed = $false
        
        # Check if import is used in code
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($i -ne $import.Index -and $lines[$i] -match $importName) {
                $isUsed = $true
                break
            }
        }
        
        if (-not $isUsed) {
            # Mark common unused imports for removal
            if ($import.Path -match 'color_extensions|design_system|navigation_provider|responsive_button|responsive_form_field|image_picker_widget|enhanced_empty_state|enhanced_form_field|cached_image|app_spacing') {
                $lines[$import.Index] = ""
            }
        }
    }
    
    $content = $lines -join "`r`n"
    
    # Remove dead code patterns
    $content = $content -replace '\?\?\s*\[\]', ''
    $content = $content -replace '\?\?\s*""', ''
    $content = $content -replace '\?\?\s*0', ''
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $modifiedFiles++
        Write-Host "Modified: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "`nCompleted!" -ForegroundColor Green
Write-Host "Processed: $processedFiles files" -ForegroundColor Cyan
Write-Host "Modified: $modifiedFiles files" -ForegroundColor Yellow
