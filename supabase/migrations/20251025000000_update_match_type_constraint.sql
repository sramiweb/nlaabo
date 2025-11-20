-- Update match_type constraint in matches table to include new values

-- Drop the existing constraint
ALTER TABLE public.matches DROP CONSTRAINT matches_match_type_check;

-- Add the new constraint with updated allowed values
ALTER TABLE public.matches ADD CONSTRAINT matches_match_type_check CHECK (match_type IN ('friendly', 'tournament', 'league', 'male', 'female', 'mixed'));