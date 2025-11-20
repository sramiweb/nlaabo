-- Team and Match Logic Constraints
-- 1. Users can create max 2 teams
-- 2. Users can create only 1 match
-- 3. Match requests require approval from team2

-- Add constraint: user can own max 2 teams
CREATE OR REPLACE FUNCTION check_team_ownership_limit()
RETURNS TRIGGER AS $$
BEGIN
  IF (SELECT COUNT(*) FROM public.teams WHERE owner_id = NEW.owner_id AND deleted_at IS NULL) >= 2 THEN
    RAISE EXCEPTION 'User can own maximum 2 teams';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_team_ownership_limit ON public.teams;
CREATE TRIGGER enforce_team_ownership_limit
  BEFORE INSERT ON public.teams
  FOR EACH ROW
  EXECUTE FUNCTION check_team_ownership_limit();

-- Add constraint: user can create only 1 match
CREATE OR REPLACE FUNCTION check_match_creation_limit()
RETURNS TRIGGER AS $$
DECLARE
  creator_id UUID;
BEGIN
  -- Get the owner_id of team1
  SELECT owner_id INTO creator_id FROM public.teams WHERE id = NEW.team1_id;
  
  -- Check if this user already created a match
  IF EXISTS (
    SELECT 1 FROM public.matches m
    JOIN public.teams t ON m.team1_id = t.id
    WHERE t.owner_id = creator_id 
    AND m.status NOT IN ('cancelled', 'completed')
  ) THEN
    RAISE EXCEPTION 'User can create only one active match at a time';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS enforce_match_creation_limit ON public.matches;
CREATE TRIGGER enforce_match_creation_limit
  BEFORE INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION check_match_creation_limit();

-- Add created_by field to track match creator
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES public.users(id);

-- Update existing matches to set created_by from team1 owner
UPDATE public.matches m
SET created_by = t.owner_id
FROM public.teams t
WHERE m.team1_id = t.id AND m.created_by IS NULL;

-- Ensure match status defaults to 'pending' for new matches
ALTER TABLE public.matches 
ALTER COLUMN status SET DEFAULT 'pending';

-- Update match status constraint to include 'pending' and 'confirmed'
ALTER TABLE public.matches 
DROP CONSTRAINT IF EXISTS matches_status_check;

ALTER TABLE public.matches 
ADD CONSTRAINT matches_status_check 
CHECK (status IN ('pending', 'confirmed', 'open', 'closed', 'completed', 'cancelled'));

-- Create notification for match request
CREATE OR REPLACE FUNCTION notify_match_request()
RETURNS TRIGGER AS $$
DECLARE
  team2_owner_id UUID;
  team1_name TEXT;
BEGIN
  -- Only send notification for new pending matches
  IF NEW.status = 'pending' AND NEW.team2_id IS NOT NULL THEN
    -- Get team2 owner
    SELECT owner_id INTO team2_owner_id FROM public.teams WHERE id = NEW.team2_id;
    
    -- Get team1 name
    SELECT name INTO team1_name FROM public.teams WHERE id = NEW.team1_id;
    
    -- Create notification
    INSERT INTO public.notifications (user_id, title, message, type, related_id)
    VALUES (
      team2_owner_id,
      'Match Request',
      team1_name || ' wants to play a match with your team',
      'match_request',
      NEW.id
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS send_match_request_notification ON public.matches;
CREATE TRIGGER send_match_request_notification
  AFTER INSERT ON public.matches
  FOR EACH ROW
  EXECUTE FUNCTION notify_match_request();

-- Add RLS policy for match creators to update their pending matches
DROP POLICY IF EXISTS "Match creators can update pending matches" ON public.matches;
CREATE POLICY "Match creators can update pending matches" ON public.matches
  FOR UPDATE USING (
    auth.uid() = created_by OR
    auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team1_id) OR
    auth.uid() = (SELECT owner_id FROM public.teams WHERE id = team2_id)
  );

-- Update existing notification types to match new constraint
UPDATE public.notifications 
SET type = 'general' 
WHERE type NOT IN ('match_invite', 'match_request', 'match_accepted', 'match_rejected', 'team_invite', 'team_join_request', 'general', 'system');

-- Add notification type for match requests
ALTER TABLE public.notifications 
DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications 
ADD CONSTRAINT notifications_type_check 
CHECK (type IN ('match_invite', 'match_request', 'match_accepted', 'match_rejected', 'team_invite', 'team_join_request', 'general', 'system'));

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_matches_created_by ON public.matches(created_by);
CREATE INDEX IF NOT EXISTS idx_matches_pending_team2 ON public.matches(team2_id, status) WHERE status = 'pending';
