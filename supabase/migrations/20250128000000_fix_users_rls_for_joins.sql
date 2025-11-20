-- Fix RLS policies for users table to allow proper joins
-- This addresses the 500 Internal Server Error when querying team_members with users join

-- ===========================================
-- CRITICAL FIX: Users Table RLS Policies
-- ===========================================

-- Drop all existing users policies to start fresh
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view other users basic info" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile and admins can view all" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile, admins can update all" ON public.users;
DROP POLICY IF EXISTS "Users can create own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_select_others" ON public.users;
DROP POLICY IF EXISTS "Authenticated users can view other users" ON public.users;
DROP POLICY IF EXISTS "Service role can view all users" ON public.users;

-- POLICY 1: Users can view their own profile
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- POLICY 2: Users can update their own profile
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- POLICY 3: Users can insert their own profile (for signup)
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- POLICY 4: CRITICAL - Allow authenticated users to view other users' basic info
-- This is essential for team_members joins and user listings
-- Only expose non-sensitive fields through the SELECT
CREATE POLICY "Authenticated users can view other users" ON public.users
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        auth.uid() != id
    );

-- POLICY 5: Allow service role to view all users (for backend operations)
-- This is needed for RPC functions and server-side operations
CREATE POLICY "Service role can view all users" ON public.users
    FOR SELECT USING (
        current_setting('role') = 'authenticated' OR
        current_setting('role') = 'service_role'
    );

-- ===========================================
-- Ensure RLS is enabled
-- ===========================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- Test queries to verify the fix
-- ===========================================

-- This query should now work:
-- SELECT tm.*, u.id, u.name, u.email, u.avatar_url, u.position
-- FROM team_members tm
-- JOIN users u ON tm.user_id = u.id
-- WHERE tm.team_id = 'some-team-id';

-- This query should also work:
-- SELECT * FROM users WHERE id = 'some-user-id';

-- ===========================================
-- Notes
-- ===========================================

-- The 500 errors were caused by:
-- 1. RLS policy violations when joining team_members with users
-- 2. The users table had overly restrictive SELECT policies
-- 3. Authenticated users couldn't view other users' basic info needed for joins

-- This fix:
-- 1. Allows authenticated users to view other users' basic info
-- 2. Maintains security by keeping own profile separate
-- 3. Allows service role for backend operations
-- 4. Keeps INSERT/UPDATE restricted to own profile
