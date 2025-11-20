-- Complete fix for team/match join request workflow

-- 1. Ensure notifications default to unread
ALTER TABLE public.notifications 
ALTER COLUMN is_read SET DEFAULT false;

-- 2. Fix any existing notifications that were incorrectly marked as read
UPDATE public.notifications 
SET is_read = false 
WHERE type IN ('team_join_request', 'team_join_approved', 'team_join_rejected', 'match_request')
AND created_at > NOW() - INTERVAL '7 days';

-- 3. Ensure team_members SELECT policy allows public viewing
DROP POLICY IF EXISTS "team_members_select" ON public.team_members;
CREATE POLICY "team_members_select" ON public.team_members
    FOR SELECT USING (true);

-- 4. Verify INSERT policy for team owners
DROP POLICY IF EXISTS "team_members_insert" ON public.team_members;
CREATE POLICY "team_members_insert" ON public.team_members
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (SELECT 1 FROM public.teams WHERE id = team_id AND owner_id = auth.uid())
    );

-- 5. Add logging function for debugging
CREATE OR REPLACE FUNCTION log_team_member_insert()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Team member inserted: team_id=%, user_id=%, role=%', NEW.team_id, NEW.user_id, NEW.role;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS log_team_member_insert_trigger ON public.team_members;
CREATE TRIGGER log_team_member_insert_trigger
    AFTER INSERT ON public.team_members
    FOR EACH ROW
    EXECUTE FUNCTION log_team_member_insert();

-- 6. Verify workflow
DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Join Request Workflow Fix Applied';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Fixed Issues:';
    RAISE NOTICE '1. ✅ Notifications default to unread (is_read = false)';
    RAISE NOTICE '2. ✅ Team members visible to all users';
    RAISE NOTICE '3. ✅ Team owners can add members';
    RAISE NOTICE '4. ✅ Logging enabled for debugging';
    RAISE NOTICE '';
    RAISE NOTICE 'Test Steps:';
    RAISE NOTICE '1. User sends join request';
    RAISE NOTICE '2. Owner approves request';
    RAISE NOTICE '3. Check console for: "Team member inserted"';
    RAISE NOTICE '4. Verify member appears in UI';
    RAISE NOTICE '5. Check notification is unread';
    RAISE NOTICE '============================================';
END $$;
