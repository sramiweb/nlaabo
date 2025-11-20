-- Fix match request acceptance to add team members to match_participants
-- This migration adds a function to bulk add team members when a match is confirmed

-- Function to add all team members from both teams to match_participants when match is confirmed
CREATE OR REPLACE FUNCTION add_team_members_to_match(p_match_id UUID)
RETURNS VOID AS $$
DECLARE
    v_team1_id UUID;
    v_team2_id UUID;
    v_member RECORD;
BEGIN
    -- Get team IDs from the match
    SELECT team1_id, team2_id INTO v_team1_id, v_team2_id
    FROM public.matches
    WHERE id = p_match_id;

    IF v_team1_id IS NULL OR v_team2_id IS NULL THEN
        RAISE EXCEPTION 'Match must have both team1_id and team2_id';
    END IF;

    -- Add all members from team1
    FOR v_member IN
        SELECT tm.user_id, tm.role
        FROM public.team_members tm
        WHERE tm.team_id = v_team1_id
    LOOP
        -- Use the existing safe function to add each member
        PERFORM add_match_participant_safe(
            p_match_id,
            v_member.user_id,
            v_team1_id,
            'confirmed'
        );
    END LOOP;

    -- Add all members from team2
    FOR v_member IN
        SELECT tm.user_id, tm.role
        FROM public.team_members tm
        WHERE tm.team_id = v_team2_id
    LOOP
        -- Use the existing safe function to add each member
        PERFORM add_match_participant_safe(
            p_match_id,
            v_member.user_id,
            v_team2_id,
            'confirmed'
        );
    END LOOP;

    -- Log the operation
    RAISE NOTICE 'Added team members to match %: team1=% has %, team2=% has % participants',
        p_match_id, v_team1_id,
        (SELECT COUNT(*) FROM public.team_members WHERE team_id = v_team1_id),
        v_team2_id,
        (SELECT COUNT(*) FROM public.team_members WHERE team_id = v_team2_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION add_team_members_to_match(UUID) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION add_team_members_to_match(UUID) IS 'Adds all members from both teams to match_participants when a match request is accepted';