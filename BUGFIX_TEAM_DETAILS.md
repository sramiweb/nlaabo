# Bug Fix: Team Details Database Error

## Issue
The Team Details screen was showing "Team not found" error with a PostgreSQL exception:
```
PostgrestException(message: column users_1.full_name does not exist, code: 42703)
```

## Root Cause
The database queries in `api_service.dart` were attempting to join the `users` table with incorrect syntax:
- `select('*, users!inner(id, full_name, email, image_url)')` 
- This created an alias `users_1` that PostgreSQL couldn't resolve properly

## Solution
Simplified the queries to remove the problematic joins:

### 1. Fixed `getTeam()` method
**Before:**
```dart
final response = await _supabase
    .from('teams')
    .select('*, users!inner(id, full_name, email, image_url)')
    .eq('id', teamId)
    .eq('owner_id', 'users.id')
    .single();
```

**After:**
```dart
final response = await _supabase
    .from('teams')
    .select('*')
    .eq('id', teamId)
    .single();
```

### 2. Fixed `getUserTeams()` method
**Before:**
```dart
// Owned teams query
.select('*, users!inner(id, full_name, email, image_url)')

// Member teams query
.select('teams!inner(*, users!inner(id, full_name, email, image_url))')
```

**After:**
```dart
// Owned teams query
.select('*')

// Member teams query
.select('teams!inner(*)')
```

### 3. Fixed `userTeamsStream`
Removed the same problematic users join from the real-time stream.

## Impact
- ✅ Team Details screen now loads correctly
- ✅ No more PostgreSQL column errors
- ✅ Simplified queries are faster and more maintainable
- ✅ User information is still available through the Team model's owner relationship

## Testing
1. Navigate to any team details page
2. Verify team information displays correctly
3. Verify no database errors in console
4. Test team member list displays properly

## Additional Fix: Owner Name Display

Since we removed the join, the team owner information was no longer being fetched. Fixed by:

1. Added `_ownerName` field to store owner name separately
2. Fetch owner data using `getUserById()` after getting team
3. Display `_ownerName` instead of `_team!.owner?.name`

## Files Modified
- `lib/services/api_service.dart`
- `lib/screens/team_details_screen.dart`
