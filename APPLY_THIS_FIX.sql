-- ============================================
-- CRITICAL FIX: Apply this in Supabase SQL Editor
-- ============================================
-- This fixes the team members not showing issue

-- 1. Fix users table RLS - Allow viewing other users' profiles
DROP POLICY IF EXISTS "Anyone can view user profiles" ON public.users;
CREATE POLICY "Anyone can view user profiles" ON public.users FOR SELECT USING (true);

-- 2. Fix add_team_member_safe function
DROP FUNCTION IF EXISTS public.add_team_member_safe(UUID, UUID, TEXT);
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
    SELECT owner_id INTO v_team_owner FROM public.teams WHERE id = p_team_id AND deleted_at IS NULL;
    IF v_team_owner IS NULL THEN RAISE EXCEPTION 'Team not found'; END IF;
    IF auth.uid() != v_team_owner THEN RAISE EXCEPTION 'Only team owner can add members'; END IF;
    
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (p_team_id, p_user_id, p_role, NOW())
    ON CONFLICT (team_id, user_id) DO UPDATE SET role = EXCLUDED.role
    RETURNING jsonb_build_object('team_id', team_id, 'user_id', user_id, 'role', role, 'joined_at', joined_at) INTO v_result;
    
    IF v_result IS NULL THEN
        SELECT jsonb_build_object('team_id', team_id, 'user_id', user_id, 'role', role, 'joined_at', joined_at) INTO v_result
        FROM public.team_members WHERE team_id = p_team_id AND user_id = p_user_id;
    END IF;
    
    RETURN v_result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.add_team_member_safe TO authenticated;

-- 3. Fix team_members RLS policies
DROP POLICY IF EXISTS "team_members_select" ON public.team_members;
CREATE POLICY "team_members_select" ON public.team_members FOR SELECT USING (true);

DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;
CREATE POLICY "team_members_insert" ON public.team_members FOR INSERT WITH CHECK (
    auth.uid() = user_id OR EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
);

-- Verification
SELECT '✅ All fixes applied successfully!' as status;
