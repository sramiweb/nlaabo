-- Verify and fix the complete team join request workflow

-- 1. Ensure team_members table has correct structure
DO $$
BEGIN
    -- Add joined_at if missing
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'team_members' AND column_name = 'joined_at'
    ) THEN
        ALTER TABLE public.team_members ADD COLUMN joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 2. Fix INSERT policy to allow team owners to add members when approving requests
DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;

CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (
        -- User can add themselves
        auth.uid() = user_id 
        OR 
        -- Team owner can add any member
        EXISTS (
            SELECT 1 FROM public.teams 
            WHERE id = team_id 
            AND owner_id = auth.uid()
        )
    );

-- 3. Create a function to safely add team members (handles duplicates)
CREATE OR REPLACE FUNCTION add_team_member_safe(
    p_team_id UUID,
    p_user_id UUID,
    p_role TEXT DEFAULT 'member'
)
RETURNS BOOLEAN AS $$
BEGIN
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (p_team_id, p_user_id, p_role, NOW())
    ON CONFLICT (team_id, user_id) DO NOTHING;
    
    RETURN TRUE;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error adding team member: %', SQLERRM;
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Grant execute permission
GRANT EXECUTE ON FUNCTION add_team_member_safe(UUID, UUID, TEXT) TO authenticated;

-- 5. Verify policies
DO $$
DECLARE
    select_policy_count INTEGER;
    insert_policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO select_policy_count
    FROM pg_policies 
    WHERE tablename = 'team_members' AND cmd = 'SELECT';
    
    SELECT COUNT(*) INTO insert_policy_count
    FROM pg_policies 
    WHERE tablename = 'team_members' AND cmd = 'INSERT';
    
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Team Members Workflow Verification';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'SELECT policies: %', select_policy_count;
    RAISE NOTICE 'INSERT policies: %', insert_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Workflow:';
    RAISE NOTICE '1. User creates join request → team_join_requests';
    RAISE NOTICE '2. Owner approves → updateJoinRequestStatus';
    RAISE NOTICE '3. Member added → team_members (via INSERT or function)';
    RAISE NOTICE '4. UI refreshes → getTeamMembers shows new member';
    RAISE NOTICE '============================================';
END $$;
