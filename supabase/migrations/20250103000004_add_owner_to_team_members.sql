-- Automatically add team owner as a member when team is created

-- Function to add owner as team member
CREATE OR REPLACE FUNCTION add_owner_as_team_member()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.team_members (team_id, user_id, role, joined_at)
    VALUES (NEW.id, NEW.owner_id, 'owner', NOW())
    ON CONFLICT (team_id, user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger
DROP TRIGGER IF EXISTS add_owner_as_member_trigger ON public.teams;
CREATE TRIGGER add_owner_as_member_trigger
    AFTER INSERT ON public.teams
    FOR EACH ROW
    EXECUTE FUNCTION add_owner_as_team_member();

-- Add existing team owners as members
INSERT INTO public.team_members (team_id, user_id, role, joined_at)
SELECT t.id, t.owner_id, 'owner', t.created_at
FROM public.teams t
WHERE NOT EXISTS (
    SELECT 1 FROM public.team_members tm 
    WHERE tm.team_id = t.id AND tm.user_id = t.owner_id
)
ON CONFLICT (team_id, user_id) DO NOTHING;
