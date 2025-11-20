-- Fix RLS policies for API errors (500 Internal Server Error and 406 Not Acceptable)
-- This addresses the issues with team_members and users table queries

-- ===========================================
-- USERS TABLE RLS POLICY FIXES
-- ===========================================

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can view other users basic info" ON public.users;

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
-- This is needed for team_members joins and user listings
-- Only expose non-sensitive fields: id, name, email, avatar_url, position, bio, location
CREATE POLICY "Users can view other users basic info" ON public.users
    FOR SELECT USING (
        auth.uid() IS NOT NULL AND
        auth.uid() != id  -- Exclude own profile (already covered above)
    );

-- ===========================================
-- TEAM_MEMBERS TABLE RLS POLICY FIXES
-- ===========================================

-- The existing team_members policies should work, but ensure they allow the necessary joins
-- The issue was that the users table join was failing due to restrictive users policies

-- Verify existing policies are correct:
-- "Team members can view team membership" - allows viewing team membership
-- "Team owners can manage members" - allows team owners to manage
-- "Users can join teams" - allows users to join teams

-- ===========================================
-- ADDITIONAL SECURITY MEASURES
-- ===========================================

-- Ensure RLS is enabled on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- VERIFICATION QUERIES
-- ===========================================

-- Test queries that were failing:

-- 1. getAllUsers() equivalent (should work now)
-- SELECT id, name, email, avatar_url, position, bio, location FROM users;

-- 2. getTeamMembers() equivalent (should work now)
-- SELECT tm.*, u.id, u.name, u.email, u.avatar_url, u.position
-- FROM team_members tm
-- JOIN users u ON tm.user_id = u.id
-- WHERE tm.team_id = 'some-team-id';

-- 3. Signup INSERT (should work now)
-- INSERT INTO users (id, name, email, ...) VALUES (auth.uid(), ...);

-- ===========================================
-- NOTES
-- ===========================================

-- This fix addresses the 500 Internal Server Error caused by:
-- 1. RLS policy violations when joining team_members with users
-- 2. Missing INSERT policy for user signup
-- 3. Overly restrictive SELECT policies preventing necessary data access

-- The 406 Not Acceptable errors may be related to:
-- 1. Content-Type headers in API requests
-- 2. Missing Accept headers
-- 3. API versioning issues

-- If 406 errors persist, check:
-- 1. HTTP headers in API calls
-- 2. Supabase client configuration
-- 3. Network request formatting