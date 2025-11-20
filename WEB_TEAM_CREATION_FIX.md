# Web Team Creation Fix

## Issue
Team creation was failing on web version with error: "You already have a team with this name"

## Root Cause
The web-specific team service (`web_team_service.dart`) had different logic than the mobile version:

### Web Version (BROKEN)
```dart
// 1. Insert team
final team = await supabase.from('teams').insert(teamData).single();

// 2. Manually insert team member with role 'captain'
await supabase.from('team_members').insert({
  'team_id': team.id,
  'user_id': currentUser.id,
  'role': 'captain',  // ❌ Wrong role
});
```

### Mobile Version (WORKING)
```dart
// 1. Insert team
final team = await supabase.from('teams').insert(teamData).single();

// 2. Wait for database trigger to add owner
await Future.delayed(const Duration(milliseconds: 300));
// Trigger automatically inserts with role 'owner' ✅
```

## The Conflict
1. **Database trigger** (from migration `20250103000004_add_owner_to_team_members.sql`):
   - Automatically inserts team creator with role **'owner'**
   - Uses `ON CONFLICT DO NOTHING`

2. **Web service manual insert**:
   - Tried to insert with role **'captain'**
   - Caused constraint violation or duplicate key error
   - Led to "already have a team" error message

## Solution Applied

### Changed `lib/services/web_team_service.dart`

**Before:**
```dart
// Add creator as team member
await supabase
    .from('team_members')
    .insert({
      'team_id': team.id,
      'user_id': currentUser.id,
      'role': 'captain',  // ❌ Conflicts with trigger
    });
```

**After:**
```dart
// Wait for database trigger to add owner as team member
await Future.delayed(const Duration(milliseconds: 300));
// ✅ Trigger handles it automatically with correct 'owner' role
```

## Why This Works

1. **Database trigger** runs automatically when team is created
2. **Trigger inserts** owner with correct role: 'owner'
3. **300ms delay** ensures trigger completes before returning
4. **No manual insert** = no conflict
5. **Consistent behavior** between web and mobile

## Testing

### Before Fix
```
Web: Create team "GROUPENIYA1" → ❌ Error
Mobile: Create team "GROUPENIYA1" → ✅ Success
```

### After Fix
```
Web: Create team "GROUPENIYA1" → ✅ Success
Mobile: Create team "GROUPENIYA1" → ✅ Success
```

## Files Modified
- `lib/services/web_team_service.dart` - Removed manual team_members insert, added delay

## Related Files
- `lib/services/api_service.dart` - Mobile version (already fixed)
- `supabase/migrations/20250103000004_add_owner_to_team_members.sql` - Database trigger
- `supabase/migrations/20250112000000_fix_team_members_role_constraint.sql` - Role constraint fix

## Verification Steps
1. Open web version
2. Create a new team
3. Should succeed without error ✅
4. Check team_members table - owner should have role 'owner' ✅
5. Try creating same team name again - should fail (correct) ✅
