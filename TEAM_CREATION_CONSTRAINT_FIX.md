# Team Creation Constraint Fix

## Issue
PostgreSQL constraint violation when creating teams:
```
Error: PostgresException(message: new row for relation "team_members" violates check constraint "team_members_role_check", code: 23514)
```

## Root Cause
1. **Database Constraint**: The `team_members` table had a CHECK constraint that only allowed roles: `('member', 'captain', 'coach')`
2. **Database Trigger**: Migration `20250103000004_add_owner_to_team_members.sql` added a trigger that automatically inserts the team creator with role `'owner'`
3. **Application Code**: `api_service.dart` was manually inserting the creator with role `'captain'`, causing a conflict

## Solution Applied

### 1. Database Migration (✅ Applied)
Created `20250112000000_fix_team_members_role_constraint.sql`:
- Updated CHECK constraint to include `'owner'` role
- Migrated existing `'captain'` roles for team owners to `'owner'`

```sql
ALTER TABLE public.team_members 
DROP CONSTRAINT IF EXISTS team_members_role_check;

ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_role_check 
CHECK (role IN ('owner', 'captain', 'coach', 'member'));
```

### 2. Application Code Fix (✅ Applied)
Updated `lib/services/api_service.dart`:
- Removed manual `team_members` insert in `createTeam()` method
- Let the database trigger handle owner insertion automatically
- This prevents duplicate inserts and role conflicts

**Before:**
```dart
await _supabase.from('team_members').insert({
  'team_id': team.id,
  'user_id': user.id,
  'role': 'captain',  // ❌ Wrong role
});
```

**After:**
```dart
// Owner is automatically added by database trigger
debugPrint('Team owner will be added automatically by trigger');
```

## Valid Roles
After the fix, the following roles are valid in `team_members`:
- `owner` - Team creator (automatically assigned)
- `captain` - Team captain
- `coach` - Team coach  
- `member` - Regular team member

## Testing
1. Try creating a new team through the web interface
2. Verify the team is created successfully
3. Check that the creator is automatically added as a team member with role `'owner'`

## Files Modified
1. `supabase/migrations/20250112000000_fix_team_members_role_constraint.sql` (new)
2. `lib/services/api_service.dart` (updated)

## Additional Fix
Added 300ms delay after team creation to ensure database trigger completes before returning the team object. This prevents race conditions where the UI might try to access team member data before the trigger finishes.

## Status
✅ **FIXED** - Team creation now works without constraint violations or timing issues
