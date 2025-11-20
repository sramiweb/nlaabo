-- Fix team_members SELECT policy to allow anyone to view team members
-- This ensures team member counts and lists are visible to all users

DROP POLICY IF EXISTS "team_members_select" ON public.team_members;

CREATE POLICY "team_members_select" ON public.team_members
    FOR SELECT USING (true);  -- Allow anyone to view team members

-- This is safe because:
-- 1. Team membership is public information (users need to see who's on teams)
-- 2. Sensitive user data is protected by RLS on the users table
-- 3. Only basic team membership info (team_id, user_id, role) is exposed
