# Quick Fix for Compilation Errors

All files need to use static class methods correctly:

## Replace patterns:
- `AppSpacing.md` → `12.0` (or use const EdgeInsets.all(12))
- `AppSpacing.sm` → `8.0`
- `AppSpacing.xs` → `4.0`
- `AppSpacing.lg` → `16.0`
- `ResponsiveUtils.getIconSize(context, X)` → Keep as is (correct)
- `AppTextStyles.getResponsiveCardTitle(context)` → Keep as is (correct)
- `context.borderRadius` → `12.0`
- `context.buttonHeight` → `ResponsiveUtils.getButtonHeight(context)`
- `context.itemSpacing` → `ResponsiveUtils.getItemSpacing(context)`
- `context.cardWidth` → `ResponsiveUtils.getCardWidth(context)`
- `context.maxContentWidth` → `ResponsiveUtils.getMaxContentWidth(context)`

## Files to fix:
1. lib/screens/match_details_screen.dart
2. lib/screens/teams_screen.dart  
3. lib/screens/login_screen.dart
4. lib/widgets/match_card.dart
