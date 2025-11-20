-- Add deleted_at column to teams table for soft deletes
ALTER TABLE public.teams 
ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- Create index for filtering active teams
CREATE INDEX IF NOT EXISTS idx_teams_deleted_at ON public.teams(deleted_at) WHERE deleted_at IS NULL;
