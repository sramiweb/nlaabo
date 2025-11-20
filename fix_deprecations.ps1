# Fix all deprecation warnings in the Flutter project

Write-Host "Fixing deprecation warnings..." -ForegroundColor Cyan

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
    
    # Fix withOpacity -> withValues
    $content = $content -replace '\.withOpacity\(([0-9.]+)\)', '.withValues(alpha: $1)'
    
    # Fix AppColors.primary -> context.colors.primary
    $content = $content -replace 'AppColors\.primary\b', 'context.colors.primary'
    $content = $content -replace 'AppColors\.secondary\b', 'context.colors.secondary'
    $content = $content -replace 'AppColors\.accent\b', 'context.colors.accent'
    $content = $content -replace 'AppColors\.surface\b', 'context.colors.surface'
    $content = $content -replace 'AppColors\.background\b', 'context.colors.background'
    $content = $content -replace 'AppColors\.error\b', 'context.colors.error'
    $content = $content -replace 'AppColors\.success\b', 'context.colors.success'
    $content = $content -replace 'AppColors\.warning\b', 'context.colors.warning'
    $content = $content -replace 'AppColors\.info\b', 'context.colors.info'
    $content = $content -replace 'AppColors\.textPrimary\b', 'context.colors.textPrimary'
    $content = $content -replace 'AppColors\.textSecondary\b', 'context.colors.textSecondary'
    $content = $content -replace 'AppColors\.textSubtle\b', 'context.colors.textSubtle'
    $content = $content -replace 'AppColors\.textDisabled\b', 'context.colors.textDisabled'
    $content = $content -replace 'AppColors\.border\b', 'context.colors.border'
    $content = $content -replace 'AppColors\.divider\b', 'context.colors.divider'
    $content = $content -replace 'AppColors\.shadow\b', 'context.colors.shadow'
    $content = $content -replace 'AppColors\.overlay\b', 'context.colors.overlay'
    $content = $content -replace 'AppColors\.cardBackground\b', 'context.colors.cardBackground'
    $content = $content -replace 'AppColors\.inputBackground\b', 'context.colors.inputBackground'
    $content = $content -replace 'AppColors\.shimmerBase\b', 'context.colors.shimmerBase'
    $content = $content -replace 'AppColors\.shimmerHighlight\b', 'context.colors.shimmerHighlight'
    
    # Fix activeColor -> activeThumbColor for Switch
    $content = $content -replace 'activeColor:', 'activeThumbColor:'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        $modifiedFiles++
        Write-Host "Modified: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "`nCompleted!" -ForegroundColor Green
Write-Host "Processed: $processedFiles files" -ForegroundColor Cyan
Write-Host "Modified: $modifiedFiles files" -ForegroundColor Yellow

Write-Host "`nRunning flutter analyze to check remaining issues..." -ForegroundColor Cyan
flutter analyze
