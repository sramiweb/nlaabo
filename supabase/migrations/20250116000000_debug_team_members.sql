-- Debug team members issue
-- This migration helps diagnose why team members aren't showing up after join approval

-- 1. Check current RLS policies on team_members
DO $$
DECLARE
    policy_record RECORD;
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Current RLS Policies on team_members table:';
    RAISE NOTICE '============================================';
    
    FOR policy_record IN 
        SELECT policyname, cmd, qual, with_check
        FROM pg_policies 
        WHERE tablename = 'team_members'
    LOOP
        RAISE NOTICE 'Policy: % | Command: % | USING: % | WITH CHECK: %', 
            policy_record.policyname, 
            policy_record.cmd,
            policy_record.qual,
            policy_record.with_check;
    END LOOP;
    
    RAISE NOTICE '============================================';
END $$;

-- 2. Ensure RLS is enabled but policies are permissive
ALTER TABLE public.team_members ENABLE ROW LEVEL SECURITY;

-- 3. Drop all existing policies and recreate with correct permissions
DROP POLICY IF EXISTS "team_members_select" ON public.team_members;
DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;
DROP POLICY IF EXISTS "team_members_update" ON public.team_members;
DROP POLICY IF EXISTS "team_members_delete" ON public.team_members;

-- Allow anyone to view team members (public read)
CREATE POLICY "team_members_select" ON public.team_members
    FOR SELECT USING (true);

-- Allow team owners to add members OR users to add themselves
CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

-- Allow team owners to update member roles
CREATE POLICY "team_members_update" ON public.team_members
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

-- Allow team owners to remove members OR users to remove themselves
CREATE POLICY "team_members_delete" ON public.team_members
    FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

-- 4. Create a function to safely add team members (bypasses RLS)
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
    
    -- Check if member already exists
    IF EXISTS (
        SELECT 1 FROM public.team_members 
        WHERE team_id = p_team_id AND user_id = p_user_id
    ) THEN
        RAISE NOTICE 'Member already exists in team';
        SELECT jsonb_build_object(
            'team_id', team_id,
            'user_id', user_id,
            'role', role,
            'joined_at', joined_at
        ) INTO v_result
        FROM public.team_members
        WHERE team_id = p_team_id AND user_id = p_user_id;
        
        RETURN v_result;
    END IF;
    
    -- Insert the team member
    INSERT INTO public.team_members (team_id, user_id, role)
    VALUES (p_team_id, p_user_id, p_role)
    RETURNING jsonb_build_object(
        'team_id', team_id,
        'user_id', user_id,
        'role', role,
        'joined_at', joined_at
    ) INTO v_result;
    
    RAISE NOTICE 'Team member added successfully: team_id=%, user_id=%, role=%', 
        p_team_id, p_user_id, p_role;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error adding team member: %', SQLERRM;
        RAISE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.add_team_member_safe TO authenticated;

-- 5. Add comprehensive logging
CREATE OR REPLACE FUNCTION log_team_member_operations()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        RAISE NOTICE '[TEAM_MEMBER_INSERT] team_id=%, user_id=%, role=%, auth_uid=%', 
            NEW.team_id, NEW.user_id, NEW.role, auth.uid();
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        RAISE NOTICE '[TEAM_MEMBER_UPDATE] team_id=%, user_id=%, old_role=%, new_role=%, auth_uid=%', 
            NEW.team_id, NEW.user_id, OLD.role, NEW.role, auth.uid();
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        RAISE NOTICE '[TEAM_MEMBER_DELETE] team_id=%, user_id=%, role=%, auth_uid=%', 
            OLD.team_id, OLD.user_id, OLD.role, auth.uid();
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_team_member_operations_trigger ON public.team_members;
CREATE TRIGGER log_team_member_operations_trigger
    BEFORE INSERT OR UPDATE OR DELETE ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION log_team_member_operations();

-- 6. Summary
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Team Members Debug Migration Applied';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Changes Made:';
    RAISE NOTICE '1. ✅ RLS policies recreated with correct permissions';
    RAISE NOTICE '2. ✅ Public SELECT access enabled';
    RAISE NOTICE '3. ✅ Team owners can INSERT members';
    RAISE NOTICE '4. ✅ Safe function created: add_team_member_safe()';
    RAISE NOTICE '5. ✅ Comprehensive logging enabled';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage in Flutter:';
    RAISE NOTICE '  await supabase.rpc(''add_team_member_safe'', {';
    RAISE NOTICE '    ''p_team_id'': teamId,';
    RAISE NOTICE '    ''p_user_id'': userId,';
    RAISE NOTICE '    ''p_role'': ''member''';
    RAISE NOTICE '  });';
    RAISE NOTICE '';
    RAISE NOTICE 'Check Supabase logs for NOTICE messages';
    RAISE NOTICE '============================================';
END $$;
