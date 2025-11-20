# Team Owner Translation and Data Loading Fix

## Issues Fixed

### 1. Translation Issue
**Problem**: Team cards were showing hardcoded Arabic text "غير محدد" instead of using the proper translation system.

**Root Cause**: In `teams_screen.dart`, the default owner info was hardcoded as:
```dart
final ownerInfo = _teamOwners[team.id] ?? {'name': 'غير محدد'};
```

**Solution**: Changed to use the translation service:
```dart
final ownerInfo = _teamOwners[team.id] ?? {'name': LocalizationService().translate('not_specified')};
```

This ensures the text displays correctly in all languages:
- English: "Not specified"
- French: "Non spécifié" 
- Arabic: "غير محدد"

### 2. Owner Data Not Loading
**Problem**: Team owner information was not being loaded when the screen first opened, only showing "Not specified" for all teams.

**Root Cause**: In the `initState()` method, only `teamProvider.loadTeams()` was called, which loads team data but not owner information. The `_loadTeams()` method that fetches owner data was only called on manual refresh.

**Solution**: Modified `initState()` to call `_loadTeams()` after teams are loaded:
```dart
teamProvider.loadTeams().then((_) {
  // Load owner data after teams are loaded
  _loadTeams();
});
```

## Files Modified

1. **lib/screens/teams_screen.dart**
   - Line 282-283: Changed hardcoded Arabic text to use translation key
   - Line 56-60: Added call to `_loadTeams()` after initial team loading

## Testing

After these changes:
1. Team cards should display owner names correctly when the screen loads
2. The "Not specified" text should appear in the correct language based on user's language setting
3. Owner information should load automatically without requiring a manual refresh

## Related Translation Keys

- `not_specified`: Used when owner information is not available
- `owner`: Label for the owner field
- `recruiting`: Status badge text
- `closed`: Status badge text when not recruiting
