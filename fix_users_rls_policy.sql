-- Fix users table RLS to allow viewing other users' public profiles
-- This is needed for team member lists, match participants, etc.

-- Add policy to allow anyone to view basic user profiles
CREATE POLICY "Anyone can view user profiles" ON public.users
    FOR SELECT USING (true);

-- Note: Sensitive data like email, phone should be protected at column level if needed
-- For now, all user data is considered public for the app to function

-- Verify policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'users'
ORDER BY policyname;
