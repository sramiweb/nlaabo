-- Fix team name constraint to allow different owners to have teams with same name
-- Remove global unique constraint and keep only per-owner constraint

-- Drop the global unique constraint that prevents different owners from using same team name
ALTER TABLE public.teams DROP CONSTRAINT IF EXISTS unique_team_name;

-- The unique_team_owner_name constraint already exists from 20251025110000_additional_indexes_constraints.sql
-- It ensures: same owner cannot have multiple teams with the same name (case-insensitive)
-- But allows: different owners to have teams with the same name

-- Verify the constraint exists (it should already be there)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'unique_team_owner_name'
    ) THEN
        -- Add it if somehow missing
        ALTER TABLE public.teams ADD CONSTRAINT unique_team_owner_name
            EXCLUDE (owner_id WITH =, lower(trim(name)) WITH =)
            WHERE (owner_id IS NOT NULL);
    END IF;
END $$;
