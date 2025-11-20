-- Comprehensive Fix: Allow Players to Leave Matches and Teams
-- This migration ensures both match_participants and team_members have proper DELETE policies

-- ============================================
-- 1. FIX TEAM_MEMBERS DELETE POLICY
-- ============================================

-- Drop ALL existing policies on team_members
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;
DROP POLICY IF EXISTS "Team members can view team membership" ON public.team_members;
DROP POLICY IF EXISTS "Team owners can manage members" ON public.team_members;
DROP POLICY IF EXISTS "Users can join teams" ON public.team_members;
DROP POLICY IF EXISTS "Users can request to join teams" ON public.team_members;
DROP POLICY IF EXISTS "Team members and owners can view membership" ON public.team_members;
DROP POLICY IF EXISTS "Team owners and captains can manage all members" ON public.team_members;
DROP POLICY IF EXISTS "Members can leave teams" ON public.team_members;

-- Create clear, separate policies for team_members

-- SELECT: Members and owners can view
CREATE POLICY "team_members_select" ON public.team_members
    FOR SELECT USING (
        user_id = auth.uid() OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid())
    );

-- INSERT: Users can join teams
CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- UPDATE: Owners and captains can update
CREATE POLICY "team_members_update" ON public.team_members
    FOR UPDATE USING (
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- DELETE: Members can leave, owners/captains can remove others
CREATE POLICY "team_members_delete" ON public.team_members
    FOR DELETE USING (
        auth.uid() = user_id OR  -- ✅ CRITICAL: Allow self-deletion
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- ============================================
-- 2. FIX MATCH_PARTICIPANTS DELETE POLICY
-- ============================================

-- Drop ALL existing policies on match_participants
DROP POLICY IF EXISTS "Users can view match participants" ON public.match_participants;
DROP POLICY IF EXISTS "Users can join matches" ON public.match_participants;
DROP POLICY IF EXISTS "Users can update their participation" ON public.match_participants;
DROP POLICY IF EXISTS "Users can leave matches, organizers can remove participants" ON public.match_participants;
DROP POLICY IF EXISTS "Participants and organizers can view match participation" ON public.match_participants;
DROP POLICY IF EXISTS "Users can join matches, organizers can add participants" ON public.match_participants;
DROP POLICY IF EXISTS "Users can update own participation, organizers can update all" ON public.match_participants;

-- Create clear, separate policies for match_participants

-- SELECT: Anyone can view participants
CREATE POLICY "match_participants_select" ON public.match_participants
    FOR SELECT USING (true);

-- INSERT: Users can join, organizers can add
CREATE POLICY "match_participants_insert" ON public.match_participants
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

-- UPDATE: Users can update own, organizers can update all
CREATE POLICY "match_participants_update" ON public.match_participants
    FOR UPDATE USING (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

-- DELETE: Users can leave, organizers can remove
CREATE POLICY "match_participants_delete" ON public.match_participants
    FOR DELETE USING (
        auth.uid() = user_id OR  -- ✅ CRITICAL: Allow self-deletion
        EXISTS (SELECT 1 FROM public.matches WHERE id = match_id AND (
            EXISTS (SELECT 1 FROM public.teams WHERE id = team1_id AND owner_id = auth.uid()) OR
            EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
        ))
    );

-- ============================================
-- 3. VERIFY POLICIES WERE CREATED
-- ============================================

DO $$
DECLARE
    team_members_delete_count INTEGER;
    match_participants_delete_count INTEGER;
BEGIN
    -- Count DELETE policies on team_members
    SELECT COUNT(*) INTO team_members_delete_count
    FROM pg_policies 
    WHERE tablename = 'team_members' 
    AND cmd = 'DELETE';
    
    -- Count DELETE policies on match_participants
    SELECT COUNT(*) INTO match_participants_delete_count
    FROM pg_policies 
    WHERE tablename = 'match_participants' 
    AND cmd = 'DELETE';
    
    RAISE NOTICE '============================================';
    RAISE NOTICE '✅ COMPREHENSIVE FIX APPLIED';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Policies created:';
    RAISE NOTICE '  team_members: % DELETE policies', team_members_delete_count;
    RAISE NOTICE '  match_participants: % DELETE policies', match_participants_delete_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Key changes:';
    RAISE NOTICE '  ✅ Members can leave teams (auth.uid() = user_id)';
    RAISE NOTICE '  ✅ Players can leave matches (auth.uid() = user_id)';
    RAISE NOTICE '  ✅ Owners/captains can still remove members';
    RAISE NOTICE '  ✅ Match organizers can still remove participants';
    RAISE NOTICE '';
    RAISE NOTICE 'Test immediately:';
    RAISE NOTICE '  1. Try leaving a team as a regular member';
    RAISE NOTICE '  2. Try leaving a match as a participant';
    RAISE NOTICE '  3. Verify success message and UI update';
    
    IF team_members_delete_count = 0 OR match_participants_delete_count = 0 THEN
        RAISE WARNING 'DELETE policies may not have been created correctly!';
    END IF;
END $$;
