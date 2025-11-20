-- Add recurrence field to matches
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS is_recurring BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS recurrence_pattern TEXT CHECK (recurrence_pattern IN ('daily', 'weekly', 'monthly'));

-- Create index for recurring matches
CREATE INDEX IF NOT EXISTS idx_matches_recurring ON public.matches(is_recurring) WHERE is_recurring = true;
