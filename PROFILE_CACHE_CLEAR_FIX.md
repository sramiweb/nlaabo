# Profile Stats Cache Clear Fix

## Issue
Profile still showing "Teams Owned: 11" even after adding forceRefresh.

## Root Cause
Web version stores cache in browser `localStorage`. The forceRefresh parameter wasn't clearing the cached data before fetching new data.

## Solution
Explicitly clear user stats cache before loading fresh data.

### Changes Made

#### 1. Added `clearUserStatsCache()` method to `api_service.dart`
```dart
Future<void> clearUserStatsCache() async {
  await _cacheService.clearUserStats();
}
```

#### 2. Updated `profile_screen.dart`
```dart
// Added ApiService import and instance
final ApiService _apiService = ApiService();

// Clear cache before loading stats
Future<void> _loadUserStats() async {
  // Clear cache first to ensure fresh data
  await _apiService.clearUserStatsCache();
  
  final stats = await authProvider.getUserStats(forceRefresh: true);
  // ...
}
```

## How It Works

### Before (Still Broken)
```
Load Stats → forceRefresh: true → Fetch from DB → Cache still has "11" → Return "11" ❌
```

### After (Fixed)
```
Load Stats → Clear Cache → forceRefresh: true → Fetch from DB → Return 0 ✅
```

## Web-Specific Issue
On web, cache is stored in `localStorage`:
- Key: `footconnect_cached_user_stats`
- Value: `{"teams_owned": 11, ...}`

The cache persists across page refreshes until explicitly cleared.

## Testing
1. **Clear browser cache manually**:
   - F12 → Application → Storage → Clear site data
   
2. **Refresh the page**

3. **Check profile**:
   - Should show "Teams Owned: 0" ✅

4. **Create a team**

5. **Refresh profile**:
   - Should show "Teams Owned: 1" ✅

## Files Modified
- `lib/services/api_service.dart` - Added clearUserStatsCache method
- `lib/screens/profile_screen.dart` - Clear cache before loading stats

## Additional Improvements
Consider clearing stats cache when:
- Team created → `await _apiService.clearUserStatsCache()`
- Team deleted → `await _apiService.clearUserStatsCache()`
- User leaves team → `await _apiService.clearUserStatsCache()`

This ensures stats are always fresh after team operations.
