-- Add match request system to require approval from both teams

-- Add status field to matches table
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending' 
CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed'));

-- Add team2_confirmed field to track if team2 accepted
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS team2_confirmed BOOLEAN DEFAULT false;

-- Update existing matches to be confirmed
UPDATE public.matches SET status = 'confirmed', team2_confirmed = true WHERE status IS NULL;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_matches_status ON public.matches(status, match_date);
CREATE INDEX IF NOT EXISTS idx_matches_team2_pending ON public.matches(team2_id, status) WHERE status = 'pending';

-- Add RLS policy for team2 owners to view pending match requests
DROP POLICY IF EXISTS "Team2 owners can view match requests" ON public.matches;
CREATE POLICY "Team2 owners can view match requests" ON public.matches
    FOR SELECT USING (
        team2_id IS NOT NULL AND 
        EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
    );

-- Add RLS policy for team2 owners to update match status
DROP POLICY IF EXISTS "Team2 owners can confirm matches" ON public.matches;
CREATE POLICY "Team2 owners can confirm matches" ON public.matches
    FOR UPDATE USING (
        team2_id IS NOT NULL AND 
        EXISTS (SELECT 1 FROM public.teams WHERE id = team2_id AND owner_id = auth.uid())
    );
