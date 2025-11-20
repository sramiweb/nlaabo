-- Fix RLS policies to allow users to leave teams and matches
-- Critical fix: Add auth.uid() = user_id to DELETE policies

-- Drop and recreate team_members DELETE policy
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;
DROP POLICY IF EXISTS "team_members_delete" ON public.team_members;

CREATE POLICY "team_members_delete" ON public.team_members
    FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- Drop and recreate match_participants DELETE policy
DROP POLICY IF EXISTS "Users can leave matches, organizers can remove participants" ON public.match_participants;
DROP POLICY IF EXISTS "match_participants_delete" ON public.match_participants;

CREATE POLICY "match_participants_delete" ON public.match_participants
    FOR DELETE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );
