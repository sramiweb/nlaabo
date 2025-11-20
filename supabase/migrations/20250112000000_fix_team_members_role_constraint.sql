-- Fix team_members role constraint to include 'owner'

-- Drop the existing constraint
ALTER TABLE public.team_members 
DROP CONSTRAINT IF EXISTS team_members_role_check;

-- Add the updated constraint with 'owner' included
ALTER TABLE public.team_members 
ADD CONSTRAINT team_members_role_check 
CHECK (role IN ('owner', 'captain', 'coach', 'member'));

-- Update any existing 'captain' roles for team owners to 'owner'
UPDATE public.team_members tm
SET role = 'owner'
FROM public.teams t
WHERE tm.team_id = t.id 
  AND tm.user_id = t.owner_id 
  AND tm.role = 'captain';
