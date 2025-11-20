-- Fix team members DELETE policy to allow members to leave teams
-- This migration fixes the issue where regular members cannot leave teams

-- Drop the existing policy that doesn't allow self-deletion
DROP POLICY IF EXISTS "Team owners and captains can manage members" ON public.team_members;

-- Create updated policy that explicitly allows members to delete themselves
CREATE POLICY "Team owners and captains can manage members" ON public.team_members
    FOR ALL USING (
        auth.uid() = user_id OR  -- ✅ Allow members to delete themselves (CRITICAL FIX)
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid()) OR
        EXISTS (SELECT 1 FROM public.team_members WHERE team_id = team_id AND user_id = auth.uid() AND role IN ('captain', 'coach'))
    );

-- Optional: Add trigger to prevent team owner from leaving their own team
-- (Owner should transfer ownership before leaving)
CREATE OR REPLACE FUNCTION prevent_owner_leave()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the user being removed is the team owner
    IF EXISTS (
        SELECT 1 FROM public.teams 
        WHERE id = OLD.team_id 
        AND owner_id = OLD.user_id
    ) THEN
        RAISE EXCEPTION 'Team owner cannot leave the team. Please transfer ownership first or delete the team.';
    END IF;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to team_members table
DROP TRIGGER IF EXISTS prevent_owner_leave_trigger ON public.team_members;
CREATE TRIGGER prevent_owner_leave_trigger
    BEFORE DELETE ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION prevent_owner_leave();

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Team leave policy fixed successfully!';
    RAISE NOTICE '';
    RAISE NOTICE 'Changes applied:';
    RAISE NOTICE '1. Members can now leave teams (auth.uid() = user_id)';
    RAISE NOTICE '2. Team owners are prevented from leaving (must transfer ownership first)';
    RAISE NOTICE '3. Captains and coaches can still manage members';
    RAISE NOTICE '';
    RAISE NOTICE 'Test the fix:';
    RAISE NOTICE '- Regular member should be able to leave team';
    RAISE NOTICE '- Team owner should get error when trying to leave';
END $$;
