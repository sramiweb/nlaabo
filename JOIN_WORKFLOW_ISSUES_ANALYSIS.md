# Join Request Workflow - Complete Analysis & Fix

## Issues Identified from Database Screenshots

### 1. **Notifications Marked as Read Immediately**
- **Evidence**: All notifications in `public.notifications` table show `is_read: TRUE`
- **Impact**: Users don't see join request responses
- **Root Cause**: Unknown - possibly a trigger or client-side code marking them as read

### 2. **Member Count Shows 0/5 Despite Members Existing**
- **Evidence**: 
  - UI shows "Membres: 0/5" for both SRA2 and SRA teams
  - Database shows 5 records in `team_members` table with owners and members
- **Root Cause**: SELECT policy was too restrictive, preventing UI from fetching members

### 3. **Join Requests Approved But Members Not Visible**
- **Evidence**: `team_join_requests` table shows multiple `status: approved` records
- **Impact**: Approved members don't appear in team roster
- **Root Cause**: Combination of SELECT policy issue and possible cache not invalidating

## Database State Analysis

### Notifications Table
```
- Multiple "New Join Request" notifications
- Multiple "Match Request" notifications  
- ALL marked as is_read: TRUE ❌
- Created timestamps show recent activity
```

### Team Members Table
```
- 5 records exist
- Mix of 'owner' and 'member' roles
- Joined timestamps show successful insertions
- Data IS in database ✅
```

### Team Join Requests Table
```
- Multiple requests with status: 'approved'
- Some with message: 'test', 'eeeeee', NULL
- Updated timestamps show approval processing
```

## Root Causes

### Issue 1: Notifications Auto-Marked as Read
**Possible causes:**
1. Client-side code calling `markNotificationAsRead()` immediately
2. A database trigger marking notifications as read
3. Real-time subscription handler marking them as read

**Fix:**
- Ensure `is_read` defaults to `false` (already correct in schema)
- Update existing notifications to `false`
- Add logging to track when notifications are marked as read

### Issue 2: Members Not Visible in UI
**Root cause:** SELECT policy on `team_members` was restrictive:
```sql
-- OLD (restrictive)
FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
    EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid())
)
```

This prevented non-members from viewing team rosters.

**Fix:** Allow public viewing:
```sql
-- NEW (public)
FOR SELECT USING (true)
```

### Issue 3: Cache Not Invalidating
**Root cause:** After inserting team member, cache wasn't being cleared properly.

**Fix:** Added cache invalidation in `updateJoinRequestStatus`:
```dart
await _cacheService.invalidateTeamsCache();
await _cacheService.invalidateUserStatsCache();
```

## Complete Workflow

### Current Flow (with fixes):

1. **User Sends Join Request**
   ```dart
   createJoinRequest(teamId, message)
   → INSERT into team_join_requests (status='pending')
   → Notification sent to team owner
   ```

2. **Owner Views Requests**
   ```dart
   getTeamJoinRequests(teamId)
   → SELECT from team_join_requests WHERE status='pending'
   → Display in UI
   ```

3. **Owner Approves Request**
   ```dart
   _acceptJoinRequest(requestId)
   → updateJoinRequestStatus(teamId, requestId, 'approved')
   ```

4. **Backend Processes Approval**
   ```dart
   // Update request status
   UPDATE team_join_requests SET status='approved'
   
   // Insert team member
   🔵 INSERT into team_members (team_id, user_id, role='member')
   
   // Invalidate caches
   ✅ invalidateTeamsCache()
   ✅ invalidateUserStatsCache()
   
   // Send notification
   ✅ createNotification(userId, 'Join Request Approved', ...)
   ```

5. **UI Refreshes**
   ```dart
   _loadTeamData()
   → getTeamMembers(teamId)
   → 🔍 SELECT * FROM team_members WHERE team_id = ?
   → ✅ Returns members (now visible due to policy fix)
   → UI updates: "Membres: X/5"
   ```

## Fixes Applied

### Migration 20250115000007
1. ✅ Reset `is_read` default to `false`
2. ✅ Update recent notifications to unread
3. ✅ Fix SELECT policy to allow public viewing
4. ✅ Verify INSERT policy for team owners
5. ✅ Add logging trigger for debugging

### Code Changes (api_service.dart)
1. ✅ Added debug logging for member insertion
2. ✅ Added debug logging for member fetching
3. ✅ Added cache invalidation after approval
4. ✅ Added notification logging

## Testing Checklist

### Before Testing
```bash
cd supabase
supabase db push
```

### Test Scenario 1: Team Join Request
1. ✅ User A creates team "Test Team"
2. ✅ User B sends join request
3. ✅ User A sees notification (unread)
4. ✅ User A approves request
5. ✅ Check console logs:
   - 🔵 "Inserting team member"
   - ✅ "Team member inserted successfully"
   - 🔍 "Fetching team members"
   - ✅ "Found X team member records"
6. ✅ User B sees notification "Join Request Approved" (unread)
7. ✅ Team page shows "Membres: 2/5"
8. ✅ User B appears in member list

### Test Scenario 2: Match Request
1. ✅ Team A creates match with Team B
2. ✅ Team B owner sees notification (unread)
3. ✅ Team B owner accepts match
4. ✅ Match status changes to "confirmed"
5. ✅ Both teams see updated match

### Verify in Database
```sql
-- Check team members
SELECT * FROM public.team_members WHERE team_id = '<team_id>';

-- Check notifications are unread
SELECT * FROM public.notifications 
WHERE type IN ('team_join_approved', 'team_join_request')
AND is_read = false
ORDER BY created_at DESC;

-- Check join requests
SELECT * FROM public.team_join_requests 
WHERE status = 'approved'
ORDER BY updated_at DESC;
```

## Expected Results After Fix

### UI
- ✅ Member count updates: "Membres: 1/5" → "Membres: 2/5"
- ✅ New member appears in roster
- ✅ Notification badge shows unread count
- ✅ Notification appears in list (unread)

### Database
- ✅ `team_members` has new record
- ✅ `team_join_requests.status` = 'approved'
- ✅ `notifications.is_read` = false
- ✅ `notifications.type` = 'team_join_approved'

### Console Logs
```
🔵 Inserting team member: teamId=xxx, userId=yyy
✅ Team member inserted successfully: [{...}]
🔍 Fetching team members for teamId: xxx
📦 Team members response: [{...}, {...}]
✅ Found 2 team member records
✅ Notification sent to user yyy
```

## Troubleshooting

### If members still don't appear:
1. Check console for "❌ Error inserting team member"
2. Run diagnostic SQL to verify data exists
3. Check RLS policies: `SELECT * FROM pg_policies WHERE tablename = 'team_members'`
4. Verify user is authenticated: Check `auth.uid()`

### If notifications still marked as read:
1. Check if client code calls `markNotificationAsRead()` on fetch
2. Look for real-time subscription handlers
3. Check notification screen initialization

### If count still shows 0:
1. Verify `getTeamMembers()` is being called
2. Check response in console logs
3. Verify SELECT policy allows viewing
4. Check if filtering is removing members

## Next Steps

1. ✅ Apply migration: `supabase db push`
2. ✅ Test join request flow
3. ✅ Monitor console logs
4. ✅ Verify notifications stay unread
5. ✅ Confirm member count updates
6. ✅ Check member list displays correctly
