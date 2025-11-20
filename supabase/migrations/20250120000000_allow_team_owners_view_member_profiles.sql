-- Allow team owners to view their team members' profiles
-- This enables team owners to see contact information (phone numbers) of accepted team members

-- Drop existing users SELECT policy
DROP POLICY IF EXISTS "Users can view own profile and admins can view all" ON public.users;

-- Create enhanced policy that allows team owners to view their team members' profiles
CREATE POLICY "Users can view own profile, team owners can view members, admins can view all" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') OR
        EXISTS (
            SELECT 1 FROM public.team_members tm
            INNER JOIN public.teams t ON tm.team_id = t.id
            WHERE tm.user_id = users.id
            AND t.owner_id = auth.uid()
        )
    );

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Team owners can now view their team members profiles including phone numbers!';
END $$;
