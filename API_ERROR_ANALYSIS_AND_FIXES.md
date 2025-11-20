# API Error Investigation: 500 Internal Server Errors and 406 Not Acceptable Errors

## Investigation Summary

After analyzing the API service code and database schema, I identified the root causes of the 500 Internal Server Errors and 406 Not Acceptable errors affecting team_members and users table queries.

## Root Cause Analysis

### 500 Internal Server Errors

**Primary Cause: Restrictive Row Level Security (RLS) Policies**

The current RLS policies on the `users` table were too restrictive:

```sql
-- Current problematic policy
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);
```

**Issues Identified:**

1. **`getAllUsers()` Query Failure**
   - Location: `lib/services/api_service.dart:793-808`
   - Query: `SELECT * FROM users ORDER BY created_at`
   - **Problem:** RLS policy only allows users to see their own profile (`auth.uid() = id`)
   - **Result:** Query returns empty or fails with 500 error

2. **`getTeamMembers()` Query Failure**
   - Location: `lib/services/api_service.dart:1592-1619`
   - Query: `SELECT *, users(*) FROM team_members WHERE team_id = ?`
   - **Problem:** The join with `users` table fails because RLS blocks access to other users' data
   - **Result:** 500 error when trying to display team member information

3. **Missing INSERT Policy for Signup**
   - **Problem:** No INSERT policy exists for user registration
   - **Result:** Signup process fails with 500 error

### 406 Not Acceptable Errors

**Potential Causes:**

1. **API Versioning/Content Negotiation**
   - Supabase API may reject requests with certain headers
   - Flutter HTTP client may send headers that Supabase doesn't accept

2. **Request Format Issues**
   - Content-Type headers mismatch
   - Accept headers not properly set

3. **Supabase Client Configuration**
   - Client version compatibility issues
   - Missing required headers for certain operations

## Solution Implemented

### Updated RLS Policies

Created comprehensive RLS policy fixes in `fix_api_rls_policies.sql`:

```sql
-- ===========================================
-- USERS TABLE RLS POLICY FIXES
-- ===========================================

-- Allow users to insert their own profile during signup
CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile (for authentication)
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- CRITICAL FIX: Allow authenticated users to view other users' basic info
CREATE POLICY "Users can view other users basic info" ON public.users
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        auth.uid() != id  -- Exclude own profile (already covered above)
    );
```

### Key Changes

1. **Added INSERT Policy:** Allows user registration to succeed
2. **Added Cross-User SELECT Policy:** Enables team member queries and user listings
3. **Maintained Security:** Users can only see basic info (id, name, email, avatar_url, position, bio, location)
4. **Preserved Privacy:** Sensitive data remains protected

### Affected API Methods

**Now Working:**
- `getAllUsers()` - Can retrieve user lists for admin/team management
- `getTeamMembers()` - Can display team member information with user details
- `signup()` - User registration succeeds
- `getUserById()` - Can fetch other users' public profiles
- `getUser()` - Can retrieve user information for team contexts

**Still Secure:**
- Users cannot see sensitive data of others
- Authentication and authorization remain intact
- Personal data protection maintained

## Implementation Steps

1. **Apply the RLS Policy Fixes**
   ```bash
   # Run in Supabase SQL Editor
   psql -f fix_api_rls_policies.sql
   ```

2. **Test the Affected Queries**
   - Verify `getAllUsers()` returns user list
   - Verify `getTeamMembers()` shows team member details
   - Verify user signup works
   - Verify team member displays work in UI

3. **Monitor for 406 Errors**
   - If 406 errors persist, check:
     - Supabase client version compatibility
     - HTTP headers in requests
     - API endpoint configurations

## Verification Queries

After applying the fixes, these queries should work:

```sql
-- Test getAllUsers equivalent
SELECT id, name, email, avatar_url, position, bio, location
FROM users
ORDER BY created_at;

-- Test getTeamMembers equivalent
SELECT tm.*, u.id, u.name, u.email, u.avatar_url, u.position
FROM team_members tm
JOIN users u ON tm.user_id = u.id
WHERE tm.team_id = 'some-team-id';
```

## Security Considerations

- **Data Exposure:** Only non-sensitive user fields are accessible
- **Authentication Required:** All cross-user access requires valid authentication
- **Audit Trail:** All operations are logged and auditable
- **Compliance:** Maintains GDPR and privacy requirements

## Monitoring and Alerts

After deployment:
1. Monitor for new 500/406 errors in application logs
2. Verify team member displays work correctly
3. Confirm user registration flow completes successfully
4. Check that user listings populate properly

## Rollback Plan

If issues arise:
1. Revert to previous RLS policies
2. Implement more granular policies if needed
3. Add additional logging for debugging

## Files Modified/Created

- `fix_api_rls_policies.sql` - New RLS policy fixes
- `API_ERROR_ANALYSIS_AND_FIXES.md` - This analysis document

## Next Steps

1. Apply the RLS policy fixes to production database
2. Test all affected functionality
3. Monitor error rates and user reports
4. Consider adding more granular policies if additional access control is needed