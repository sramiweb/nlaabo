-- Fix team_join_requests unique constraint to allow multiple requests per user
-- Only one PENDING request should be allowed per team/user combination

-- Drop the old constraint
ALTER TABLE public.team_join_requests 
DROP CONSTRAINT IF EXISTS team_join_requests_team_id_user_id_status_key;

-- Add new constraint: only one pending request per team/user
DROP INDEX IF EXISTS idx_team_join_requests_pending_unique;
CREATE UNIQUE INDEX idx_team_join_requests_pending_unique 
ON public.team_join_requests(team_id, user_id) 
WHERE status = 'pending';

-- Add index for better query performance
DROP INDEX IF EXISTS idx_team_join_requests_status;
CREATE INDEX idx_team_join_requests_status 
ON public.team_join_requests(status, created_at DESC);
