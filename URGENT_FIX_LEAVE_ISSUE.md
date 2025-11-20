# URGENT: Fix Leave Match/Team Issue - Step by Step

## Problem
Players CANNOT leave matches or teams. The delete operation silently fails due to RLS policies.

## Root Cause
The RLS DELETE policies are missing `auth.uid() = user_id` which allows users to delete their own records.

## IMMEDIATE FIX - Follow These Steps

### Step 1: Run Diagnostic (Optional but Recommended)
```sql
-- Copy and paste this in Supabase SQL Editor
-- File: supabase/migrations/DIAGNOSTIC_check_rls_policies.sql
```
This will show you the current policies and confirm the issue.

### Step 2: Apply the Comprehensive Fix

#### Option A: Using Supabase CLI (Fastest)
```bash
cd d:\Projets\Dev\footconnect\footconnect\nlaabo
supabase db push
```

#### Option B: Manual SQL Execution (If CLI doesn't work)
1. Open Supabase Dashboard → SQL Editor
2. Copy the ENTIRE contents of:
   `supabase/migrations/20250101000001_fix_leave_policies_comprehensive.sql`
3. Paste and click **RUN**
4. Wait for success message

### Step 3: Verify the Fix

Run this query in Supabase SQL Editor:
```sql
-- Check if DELETE policies exist and include self-deletion
SELECT 
    tablename,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename IN ('team_members', 'match_participants')
AND cmd = 'DELETE'
ORDER BY tablename, policyname;
```

**Expected Result**: You should see DELETE policies that include `(auth.uid() = user_id)`

### Step 4: Test in the App

1. **Test Team Leave**:
   - Login as a regular team member (not owner)
   - Go to team details
   - Click "Leave Team"
   - ✅ User should disappear from list
   - ✅ Success message should show
   - ✅ Refresh page - user should still be gone

2. **Test Match Leave**:
   - Login as a match participant
   - Go to match details
   - Click "Leave Match"
   - ✅ User should disappear from list
   - ✅ Success message should show
   - ✅ Refresh page - user should still be gone

## What the Fix Does

### Before (BROKEN)
```sql
-- team_members DELETE policy
FOR DELETE USING (
    EXISTS (SELECT 1 FROM teams WHERE owner_id = auth.uid())  -- Only owners
);
```
❌ Regular members CANNOT delete themselves

### After (FIXED)
```sql
-- team_members DELETE policy
FOR DELETE USING (
    auth.uid() = user_id OR  -- ✅ Members can delete themselves
    EXISTS (SELECT 1 FROM teams WHERE owner_id = auth.uid())
);
```
✅ Regular members CAN delete themselves

## Why This Happened

The enhanced security migration (`20251025100000_enhanced_security_policies.sql`) used `FOR ALL` policies which are complex and didn't explicitly allow self-deletion. The new migration uses separate policies for each operation (SELECT, INSERT, UPDATE, DELETE) which are clearer and more maintainable.

## Troubleshooting

### Issue: Migration fails with "policy already exists"
**Solution**: The migration drops all existing policies first. If it still fails:
```sql
-- Manually drop all policies
DROP POLICY IF EXISTS "team_members_delete" ON public.team_members;
DROP POLICY IF EXISTS "match_participants_delete" ON public.match_participants;
-- Then run the migration again
```

### Issue: Still can't leave after applying migration
**Checklist**:
1. ✅ Migration was applied successfully (check Supabase logs)
2. ✅ User is authenticated (check `auth.uid()` is not null)
3. ✅ User is actually a member/participant (check database)
4. ✅ No JavaScript errors in browser console
5. ✅ Network request completes (check Network tab)

**Debug Query**:
```sql
-- Replace with actual IDs
SELECT 
    tm.*,
    t.owner_id,
    auth.uid() as current_user
FROM team_members tm
JOIN teams t ON tm.team_id = t.id
WHERE tm.team_id = 'YOUR_TEAM_ID'
AND tm.user_id = 'YOUR_USER_ID';
```

### Issue: Error "Team owner cannot leave"
**This is expected!** Team owners must transfer ownership before leaving. This is a safety feature.

## Files Created

1. `supabase/migrations/DIAGNOSTIC_check_rls_policies.sql` - Diagnostic script
2. `supabase/migrations/20250101000001_fix_leave_policies_comprehensive.sql` - The fix
3. `URGENT_FIX_LEAVE_ISSUE.md` - This guide

## Rollback (Emergency Only)

If something goes wrong:
```sql
-- This will restore the broken state (not recommended)
-- Better to fix forward by adjusting the policies
```

## Success Criteria

✅ Regular team members can leave teams  
✅ Match participants can leave matches  
✅ Team owners cannot leave (must transfer ownership)  
✅ Owners/captains can still remove members  
✅ Match organizers can still remove participants  
✅ No errors in console  
✅ UI updates correctly  

## Priority
🔴 **CRITICAL** - Apply immediately

## Estimated Time
- Apply fix: 2 minutes
- Test: 3 minutes
- **Total: 5 minutes**

---

**Status**: Ready to apply  
**Next Action**: Run Step 2 above  
**Date**: 2025
