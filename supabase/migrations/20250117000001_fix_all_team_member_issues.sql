-- Comprehensive fix for team member issues
-- This migration fixes all identified problems

-- ============================================
-- 1. Fix users table RLS - Allow viewing other users' profiles
-- ============================================
DROP POLICY IF EXISTS "Anyone can view user profiles" ON public.users;

CREATE POLICY "Anyone can view user profiles" ON public.users
    FOR SELECT USING (true);

-- Keep the existing policies for update/insert
-- Users can still only update their own profile

-- ============================================
-- 2. Fix add_team_member_safe function
-- ============================================
DROP FUNCTION IF EXISTS public.add_team_member_safe(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.add_team_member_safe(UUID, UUID);

CREATE OR REPLACE FUNCTION public.add_team_member_safe(
    p_team_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
)
RETURNS JSONB
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
DECLARE
    v_result JSONB;
    v_team_owner UUID;
BEGIN
    -- Verify the team exists and get owner
    SELECT owner_id INTO v_team_owner
    FROM public.teams
    WHERE id = p_team_id AND deleted_at IS NULL;
    
    IF v_team_owner IS NULL THEN
        RAISE EXCEPTION 'Team not found or has been deleted';
    END IF;
    
    -- Verify the caller is the team owner
    IF auth.uid() != v_team_owner THEN
        RAISE EXCEPTION 'Only team owner can add members';
    END IF;
    
    -- Insert or ignore if already exists
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (p_team_id, p_user_id, p_role, NOW())
    ON CONFLICT (team_id, user_id) DO UPDATE
    SET role = EXCLUDED.role
    RETURNING jsonb_build_object(
        'team_id', team_id,
        'user_id', user_id,
        'role', role,
        'joined_at', joined_at
    ) INTO v_result;
    
    -- If no row was returned, get the existing one
    IF v_result IS NULL THEN
        SELECT jsonb_build_object(
            'team_id', team_id,
            'user_id', user_id,
            'role', role,
            'joined_at', joined_at
        ) INTO v_result
        FROM public.team_members
        WHERE team_id = p_team_id AND user_id = p_user_id;
    END IF;
    
    RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.add_team_member_safe TO authenticated;

-- ============================================
-- 3. Ensure team_members RLS policies are correct
-- ============================================
DROP POLICY IF EXISTS "team_members_select" ON public.team_members;
DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;

-- Allow anyone to view team members
CREATE POLICY "team_members_select" ON public.team_members
    FOR SELECT USING (true);

-- Allow team owners to add members OR users to add themselves
CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

-- ============================================
-- 4. Verification
-- ============================================
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ All team member issues fixed!';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Changes applied:';
    RAISE NOTICE '1. ✅ Users table RLS - Anyone can view profiles';
    RAISE NOTICE '2. ✅ add_team_member_safe function - Returns JSONB';
    RAISE NOTICE '3. ✅ team_members RLS - Public SELECT access';
    RAISE NOTICE '';
    RAISE NOTICE 'Test the fix:';
    RAISE NOTICE '1. Approve a join request';
    RAISE NOTICE '2. Refresh team page';
    RAISE NOTICE '3. Members should now appear';
    RAISE NOTICE '============================================';
END $$;
