-- Fix add_team_member_safe function to work correctly
-- Run this in Supabase SQL Editor

-- Drop all versions of the function
DROP FUNCTION IF EXISTS public.add_team_member_safe(UUID, UUID, TEXT);
DROP FUNCTION IF EXISTS public.add_team_member_safe(UUID, UUID);

-- Create the correct version that returns JSONB
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
    v_existing_member RECORD;
BEGIN
    RAISE NOTICE '🔵 add_team_member_safe called: team_id=%, user_id=%, role=%', p_team_id, p_user_id, p_role;
    
    -- Verify the team exists and get owner
    SELECT owner_id INTO v_team_owner
    FROM public.teams
    WHERE id = p_team_id AND deleted_at IS NULL;
    
    IF v_team_owner IS NULL THEN
        RAISE EXCEPTION 'Team not found or has been deleted';
    END IF;
    
    RAISE NOTICE '✅ Team found, owner: %', v_team_owner;
    
    -- Verify the caller is the team owner
    IF auth.uid() != v_team_owner THEN
        RAISE EXCEPTION 'Only team owner can add members';
    END IF;
    
    RAISE NOTICE '✅ Caller is team owner';
    
    -- Check if member already exists
    SELECT * INTO v_existing_member
    FROM public.team_members 
    WHERE team_id = p_team_id AND user_id = p_user_id;
    
    IF FOUND THEN
        RAISE NOTICE '⚠️ Member already exists in team';
        SELECT jsonb_build_object(
            'team_id', team_id,
            'user_id', user_id,
            'role', role,
            'joined_at', joined_at,
            'already_exists', true
        ) INTO v_result
        FROM public.team_members
        WHERE team_id = p_team_id AND user_id = p_user_id;
        
        RETURN v_result;
    END IF;
    
    RAISE NOTICE '🔵 Inserting new team member...';
    
    -- Insert the team member
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (p_team_id, p_user_id, p_role, NOW())
    RETURNING jsonb_build_object(
        'team_id', team_id,
        'user_id', user_id,
        'role', role,
        'joined_at', joined_at,
        'already_exists', false
    ) INTO v_result;
    
    RAISE NOTICE '✅ Team member added successfully: %', v_result;
    
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '❌ Error adding team member: %', SQLERRM;
        RAISE;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.add_team_member_safe TO authenticated;

-- Verify the function was created
SELECT 
    'Function created successfully: ' || p.proname || 
    '(' || pg_get_function_arguments(p.oid) || ') RETURNS ' || 
    pg_get_function_result(p.oid) as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_team_member_safe';
