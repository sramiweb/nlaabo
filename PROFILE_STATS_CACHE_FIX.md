# Profile Stats Cache Fix - "11" Issue

## Problem
Profile screen showing "Teams Owned: 11" in User Statistics section, but:
- Database query returns: 0 ✅
- Top section shows: 0 ✅
- My Teams section shows: "No teams yet" ✅

**Root Cause**: Stale cached data returning "11" instead of fresh data from database.

## Solution
Added `forceRefresh` parameter to bypass cache and fetch fresh data.

### Changes Made

#### 1. `lib/services/api_service.dart`
```dart
Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
  // Force refresh bypasses cache
  if (forceRefresh) {
    final stats = await _fetchUserStatsFromNetwork();
    await _cacheService.cacheUserStats(stats);
    return stats;
  }
  // ... rest of cache logic
}
```

#### 2. `lib/providers/auth_provider.dart`
```dart
Future<Map<String, dynamic>> getUserStats({bool forceRefresh = false}) async {
  return await _apiService.getUserStats(forceRefresh: forceRefresh);
}
```

#### 3. `lib/screens/profile_screen.dart`
```dart
final stats = await authProvider.getUserStats(forceRefresh: true);
```

## How It Works

### Before (Broken)
```
Profile Screen → getUserStats() → Check Cache → Return "11" (stale) ❌
```

### After (Fixed)
```
Profile Screen → getUserStats(forceRefresh: true) → Fetch from DB → Return 0 ✅
```

## Why This Happened
1. User created teams in previous session
2. Stats cached with value "11"
3. User deleted/left teams
4. Cache not invalidated
5. Profile kept showing old cached value "11"

## Testing
1. Refresh the web page
2. Profile should now show "Teams Owned: 0" in all sections
3. Create a team
4. Refresh profile
5. Should show "Teams Owned: 1"

## Files Modified
- `lib/services/api_service.dart` - Added forceRefresh parameter
- `lib/providers/auth_provider.dart` - Pass through forceRefresh
- `lib/screens/profile_screen.dart` - Use forceRefresh: true

## Additional Fix Needed
Consider invalidating stats cache when:
- Team is created
- Team is deleted
- User leaves team
- User joins team

Add to team operations:
```dart
await _cacheService.clearUserStats();
```
