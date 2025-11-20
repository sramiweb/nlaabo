# Team Members Fix Instructions

## Problem
Join requests are approved but members don't appear (showing 0/5).

## Root Cause
Users table RLS policy only allows viewing own profile, blocking the JOIN query that fetches team member details.

## Solution

### Step 1: Apply Database Fix
Copy and paste the contents of `APPLY_THIS_FIX.sql` into your Supabase SQL Editor and run it.

Or run this command:
```bash
supabase db execute -f APPLY_THIS_FIX.sql
```

### Step 2: Test
1. Go to a team page
2. Approve a join request (or create a new one and approve it)
3. Refresh the page
4. Members should now appear with correct count

## What Was Fixed

1. ✅ **Users RLS Policy**: Added policy to allow anyone to view user profiles (needed for team member lists)
2. ✅ **add_team_member_safe Function**: Fixed to return JSONB and handle duplicates properly
3. ✅ **team_members RLS**: Ensured SELECT policy allows public access
4. ✅ **Notification Types**: Fixed invalid notification types in code
5. ✅ **Error Handling**: Improved duplicate member error handling

## Files Modified

### Database
- `APPLY_THIS_FIX.sql` - Main fix to apply

### Code
- `lib/services/api_service.dart` - Fixed notification types and error handling

## Verification

After applying the fix, check:
- [ ] Team members appear after approval
- [ ] Member count updates correctly
- [ ] No errors in console
- [ ] Notifications work properly
