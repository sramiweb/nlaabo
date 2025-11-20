# Profile Screen Issues & Fixes

## Issues Identified from Image

### 1. "Équipes possédées" shows "11" instead of actual count
**Problem**: Displaying wrong number (11) instead of actual teams owned count

**Possible Causes**:
- Stats not loading properly
- Cache returning stale data
- Default value being displayed

**Fix**: Clear cache and ensure stats load correctly
```dart
// In profile_screen.dart initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadUserData();
    _loadUserStats(); // Ensure this is called
  });
}
```

### 2. Missing User Name/Email at Top
**Problem**: Profile header should show user name and email prominently

**Current**: Only shows Age and Genre
**Expected**: Should show Name, Email, Age, Genre

**Check**: Verify user data is loaded in `_currentUser`

### 3. Inconsistent Data
**Problem**: Shows "Pas encore d'équipes" (No teams yet) but stats show "11" teams

**This indicates**:
- Stats are not synced with actual data
- Cache issue
- Query returning wrong data

## Debug Steps

### Step 1: Check if stats are loading
Add debug prints in `_loadUserStats()`:
```dart
Future<void> _loadUserStats() async {
  try {
    final stats = await authProvider.getUserStats();
    debugPrint('📊 User stats loaded: $stats'); // Add this
    if (mounted && !_isDisposed) {
      setState(() => _userStats = stats);
    }
  } catch (e) {
    debugPrint('❌ Failed to load stats: $e');
  }
}
```

### Step 2: Verify database query
Run in Supabase SQL Editor:
```sql
-- Check actual teams owned by current user
SELECT COUNT(*) as teams_count
FROM teams
WHERE owner_id = auth.uid();

-- Check team_members for current user
SELECT t.name, tm.role
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
WHERE tm.user_id = auth.uid();
```

### Step 3: Clear cache
```dart
// Add button to clear cache for testing
ElevatedButton(
  onPressed: () async {
    await _cacheService.clearAll();
    await _loadUserStats();
  },
  child: Text('Refresh Stats'),
)
```

## Quick Fixes

### Fix 1: Force Stats Refresh
```dart
// In profile_screen.dart
Future<void> _loadUserStats() async {
  if (_isDisposed) return;
  
  setState(() => _isLoadingStats = true);
  
  try {
    final authProvider = context.read<AuthProvider>();
    // Force fresh fetch, bypass cache
    final stats = await _apiService._fetchUserStatsFromNetwork();
    
    if (mounted && !_isDisposed) {
      setState(() {
        _userStats = stats;
        _isLoadingStats = false;
      });
    }
  } catch (e) {
    debugPrint('Failed to load user stats: $e');
    if (mounted && !_isDisposed) {
      setState(() => _isLoadingStats = false);
    }
  }
}
```

### Fix 2: Add Loading State
Show loading indicator while stats load:
```dart
_isLoadingStats
  ? CircularProgressIndicator()
  : _buildEnhancedStatCard(
      LocalizationService().translate('teams_owned'),
      _userStats['teams_owned']?.toString() ?? '0',
      Icons.group,
      Theme.of(context).colorScheme.tertiary,
    )
```

### Fix 3: Add Refresh Button
```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () {
    _loadUserData();
    _loadUserStats();
  },
)
```

## Testing Checklist

After fixes:
- [ ] Stats show correct numbers (not "11")
- [ ] User name displays at top
- [ ] User email displays
- [ ] "Mes équipes" section shows actual teams
- [ ] Stats match actual data in database
- [ ] Refresh button updates stats
- [ ] No "Pas encore d'équipes" when teams exist

## Files to Check
- `lib/screens/profile_screen.dart` - Main profile UI
- `lib/providers/auth_provider.dart` - getUserStats method
- `lib/services/api_service.dart` - _fetchUserStatsFromNetwork
- `lib/services/cache_service.dart` - Cache management
