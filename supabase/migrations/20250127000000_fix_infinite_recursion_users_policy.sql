-- Fix infinite recursion detected in users RLS policy
-- The issue occurs when policies reference other tables that have policies referencing back

-- ===========================================
-- DROP PROBLEMATIC POLICIES
-- ===========================================

DROP POLICY IF EXISTS "Users can view other users basic info" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "users_select_others" ON public.users;

-- ===========================================
-- CREATE SIMPLE NON-RECURSIVE POLICIES
-- ===========================================

-- Allow users to insert their own profile during signup
CREATE POLICY "users_insert_own" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow users to view their own profile
CREATE POLICY "users_select_own" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Allow users to update their own profile
CREATE POLICY "users_update_own" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Allow authenticated users to view other users (simple, non-recursive)
-- This is needed for team_members joins and user listings
CREATE POLICY "users_select_others" ON public.users
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- ===========================================
-- ENSURE RLS IS ENABLED
-- ===========================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
