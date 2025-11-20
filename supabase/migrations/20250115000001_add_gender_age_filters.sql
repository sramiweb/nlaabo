-- Add gender and age filtering for teams and matches

-- Add gender field to teams
ALTER TABLE public.teams 
ADD COLUMN IF NOT EXISTS gender TEXT DEFAULT 'mixed' 
CHECK (gender IN ('male', 'female', 'mixed'));

-- Add age range fields to teams
ALTER TABLE public.teams 
ADD COLUMN IF NOT EXISTS min_age INTEGER,
ADD COLUMN IF NOT EXISTS max_age INTEGER;

-- Add check constraint for age range
ALTER TABLE public.teams 
ADD CONSTRAINT teams_age_range_check 
CHECK (
  (min_age IS NULL AND max_age IS NULL) OR
  (min_age IS NOT NULL AND max_age IS NOT NULL AND min_age <= max_age AND min_age >= 13 AND max_age <= 100)
);

-- Update existing teams to mixed gender
UPDATE public.teams SET gender = 'mixed' WHERE gender IS NULL;

-- Create index for filtering
CREATE INDEX IF NOT EXISTS idx_teams_gender ON public.teams(gender);
CREATE INDEX IF NOT EXISTS idx_teams_age_range ON public.teams(min_age, max_age);

-- Add function to check if user can see team based on gender
CREATE OR REPLACE FUNCTION can_view_team(team_gender TEXT, user_gender TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  -- Mixed teams visible to all
  IF team_gender = 'mixed' THEN
    RETURN TRUE;
  END IF;
  
  -- Gender-specific teams only visible to same gender
  RETURN team_gender = user_gender;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Add function to check age compatibility
CREATE OR REPLACE FUNCTION is_age_compatible(team_min_age INTEGER, team_max_age INTEGER, user_age INTEGER)
RETURNS BOOLEAN AS $$
BEGIN
  -- No age restriction
  IF team_min_age IS NULL OR team_max_age IS NULL THEN
    RETURN TRUE;
  END IF;
  
  -- User age not set
  IF user_age IS NULL THEN
    RETURN TRUE;
  END IF;
  
  -- Check if user age is within range
  RETURN user_age >= team_min_age AND user_age <= team_max_age;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
