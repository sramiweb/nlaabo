# Fix: Players Cannot Leave Teams

## Issue Summary
Players cannot leave teams. The API call succeeds without errors, but the database delete operation is blocked by Row Level Security (RLS) policies.

## Root Cause
The RLS policy on `team_members` table does NOT allow regular members to delete themselves. It only allows:
- Team owners to delete any member ✅
- Captains/coaches to delete any member ✅
- **Regular members to delete themselves** ❌ **MISSING**

## Current Policy (BROKEN)
```sql
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );
```

## Solution Applied

### Migration File Created
`supabase/migrations/20250101000000_fix_team_leave_policy.sql`

### Changes
1. **Added self-deletion permission**: `auth.uid() = user_id`
2. **Added owner protection**: Team owners cannot leave (must transfer ownership first)

### New Policy (FIXED)
```sql
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        auth.uid() = user_id OR  -- ✅ CRITICAL FIX: Allow members to delete themselves
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );
```

## How to Apply the Fix

### Option 1: Using Supabase CLI (Recommended)
```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo
supabase db push
```

### Option 2: Manual SQL Execution
1. Open Supabase Dashboard
2. Go to SQL Editor
3. Copy and paste the contents of `supabase/migrations/20250101000000_fix_team_leave_policy.sql`
4. Click "Run"

### Option 3: Using the batch file
```bash
# If you have a migration script
.\apply-migrations.bat
```

## Testing Checklist

After applying the migration:

### Team Leave Functionality
- [ ] Regular member can leave team (should work now ✅)
- [ ] Team owner cannot leave team (should show error ✅)
- [ ] Captain can remove members (should still work ✅)
- [ ] Coach can remove members (should still work ✅)
- [ ] User cannot delete other users' memberships (should still be blocked ✅)

### UI Testing
- [ ] Click "Leave Team" button as regular member
- [ ] User disappears from members list immediately (optimistic update)
- [ ] Success message shows
- [ ] Can request to rejoin after leaving
- [ ] Error handling works if network fails

### Match Leave (Should Already Work)
- [ ] Regular member can leave match
- [ ] Match organizer can remove participants
- [ ] Optimistic UI update works

## Files Modified

### New Files
1. `supabase/migrations/20250101000000_fix_team_leave_policy.sql` - Migration to fix RLS policy
2. `LEAVE_MATCH_TEAM_RLS_ISSUE_ANALYSIS.md` - Detailed analysis
3. `FIX_LEAVE_TEAM_ISSUE.md` - This file

### Existing Files (Already Fixed)
1. `lib/screens/team_details_screen.dart` - Already has leave team UI and optimistic updates ✅
2. `lib/services/api_service.dart` - Already has leaveTeam() method ✅

## Why This Happened

The enhanced security policies migration (`20251025100000_enhanced_security_policies.sql`) improved security but accidentally removed the ability for regular members to leave teams. The policy was designed to prevent unauthorized deletions but was too restrictive.

## Additional Improvements

### Owner Protection
The migration also adds a trigger to prevent team owners from leaving their own team:
```sql
CREATE TRIGGER prevent_owner_leave_trigger
    BEFORE DELETE ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION prevent_owner_leave();
```

This ensures data integrity by requiring ownership transfer before leaving.

## Rollback (If Needed)

If you need to rollback this migration:
```sql
-- Remove the trigger
DROP TRIGGER IF EXISTS prevent_owner_leave_trigger ON public.team_members;
DROP FUNCTION IF EXISTS prevent_owner_leave();

-- Restore the old policy (not recommended - it's broken)
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );
```

## Status
✅ **FIXED** - Migration created and ready to apply

## Priority
🔴 **CRITICAL** - Blocks core functionality

## Estimated Time
- Apply migration: 2 minutes
- Test: 5 minutes
- **Total: 7 minutes**

---

**Next Steps**:
1. Apply the migration using one of the methods above
2. Test team leave functionality
3. Verify owner protection works
4. Update any documentation if needed

**Date**: 2025
