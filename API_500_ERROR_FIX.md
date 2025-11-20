# API 500 Error Fix Guide

## Problem Summary

Your app is experiencing 500 Internal Server Errors from Supabase when:
- Querying users by ID: `GET /rest/v1/users?select=*&id=eq.{userId}`
- Fetching team members: `GET /rest/v1/team_members?select=*,users(*)&team_id=eq.{teamId}`

## Root Cause

**RLS (Row Level Security) Policy Conflicts** - The users table has overly restrictive SELECT policies that prevent joins from working properly.

### The Issue

When you query `team_members` with a join to `users`:
```sql
SELECT tm.*, u.* FROM team_members tm
JOIN users u ON tm.user_id = u.id
WHERE tm.team_id = 'some-id'
```

The RLS policy on the `users` table is blocking the join because:
1. The authenticated user doesn't have permission to view other users
2. The policy doesn't allow the join operation
3. This causes a 500 error instead of a 403 Forbidden

## Solution

### Step 1: Apply the RLS Policy Fix

Run the migration file:
```bash
supabase db push
```

This applies the new migration: `20250128000000_fix_users_rls_for_joins.sql`

The fix:
- Allows authenticated users to view other users' basic info
- Maintains security by keeping own profile separate
- Allows service role for backend operations

### Step 2: Verify the Fix

Run the diagnostic script:
```bash
supabase db execute < supabase/migrations/DIAGNOSTIC_api_errors.sql
```

Check that:
1. RLS is enabled on all tables
2. Users table has 4-5 policies (not conflicting)
3. Team members policies allow joins

### Step 3: Test the Queries

In Supabase dashboard, run these queries:

**Test 1: View own profile**
```sql
SELECT * FROM users WHERE id = auth.uid();
```
Expected: Returns your profile

**Test 2: View other users**
```sql
SELECT id, name, email, avatar_url FROM users WHERE id != auth.uid() LIMIT 5;
```
Expected: Returns other users' basic info

**Test 3: Join team_members with users**
```sql
SELECT tm.*, u.id, u.name FROM team_members tm
JOIN users u ON tm.user_id = u.id LIMIT 5;
```
Expected: Returns team members with user info

### Step 4: Clear App Cache

After applying the fix:
1. Clear app cache: `flutter clean`
2. Rebuild: `flutter pub get`
3. Restart the app

## Code Changes Needed

### In `lib/services/api_service.dart`

The code is already correct. The issue is purely database-side. However, you can improve error handling:

```dart
// Add better error logging for 500 errors
Future<List<app_user.User>> getTeamMembers(String teamId) async {
  return ErrorHandler.withFallback(
    () async {
      debugPrint('🔍 Fetching team members for teamId: $teamId');
      
      try {
        final dynamic response = await _supabase
            .from('team_members')
            .select('*, users(*)')  // This join was failing due to RLS
            .eq('team_id', teamId);

        if (response == null) return <app_user.User>[];
        if (response is! List) return <app_user.User>[];
        
        return response.map((dynamic json) {
          final dynamic userData = json['users'];
          if (userData == null || userData is! Map<String, dynamic>) return null;
          try {
            return app_user.User.fromJson(userData);
          } catch (e) {
            debugPrint('❌ Error parsing user data: $e');
            return null;
          }
        }).where((user) => user != null).cast<app_user.User>().toList();
      } catch (e) {
        debugPrint('❌ Error in getTeamMembers: $e');
        // Log the full error for debugging
        if (e.toString().contains('500')) {
          debugPrint('⚠️ 500 Error - This is likely an RLS policy issue');
        }
        rethrow;
      }
    },
    <app_user.User>[],
    context: 'ApiService.getTeamMembers',
  );
}
```

## Troubleshooting

### If you still see 500 errors:

1. **Check Supabase Logs**
   - Go to Supabase Dashboard → Logs
   - Look for the actual error message
   - Common messages:
     - "permission denied for schema public" → RLS issue
     - "relation does not exist" → Missing table/column
     - "violates foreign key constraint" → Data integrity issue

2. **Verify RLS Policies**
   ```sql
   SELECT * FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users';
   ```
   Should show 4-5 policies, not conflicting

3. **Check Foreign Keys**
   ```sql
   SELECT * FROM information_schema.key_column_usage 
   WHERE table_schema = 'public' AND table_name = 'team_members';
   ```
   Verify all foreign keys are valid

4. **Test with Service Role**
   - In Supabase dashboard, use the service role key
   - If queries work with service role but not authenticated, it's an RLS issue

### If queries still timeout:

1. **Add missing indexes**
   ```sql
   CREATE INDEX idx_team_members_team_user ON team_members(team_id, user_id);
   CREATE INDEX idx_users_id ON users(id);
   ```

2. **Check query performance**
   ```sql
   EXPLAIN ANALYZE
   SELECT tm.*, u.* FROM team_members tm
   JOIN users u ON tm.user_id = u.id
   WHERE tm.team_id = 'some-id';
   ```

## Prevention

To prevent similar issues in the future:

1. **Always test RLS policies with joins**
   - Test SELECT with joins before deploying
   - Use the diagnostic script regularly

2. **Use proper policy structure**
   - Keep policies simple and non-recursive
   - Avoid complex subqueries in policies
   - Test with different user roles

3. **Monitor logs**
   - Check Supabase logs regularly
   - Set up alerts for 500 errors
   - Log all API errors in your app

## Related Files

- Migration: `supabase/migrations/20250128000000_fix_users_rls_for_joins.sql`
- Diagnostic: `supabase/migrations/DIAGNOSTIC_api_errors.sql`
- API Service: `lib/services/api_service.dart`
- Error Handler: `lib/services/error_handler.dart`

## Next Steps

1. Apply the migration
2. Run the diagnostic script
3. Test the queries
4. Monitor the logs
5. Clear app cache and rebuild
6. Test the app

If issues persist, check the Supabase logs for the actual error message.
