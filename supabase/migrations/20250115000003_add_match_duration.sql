-- Add duration field to matches (in minutes)
ALTER TABLE public.matches 
ADD COLUMN IF NOT EXISTS duration_minutes INTEGER DEFAULT 90;

-- Add constraint for valid duration
ALTER TABLE public.matches 
ADD CONSTRAINT matches_duration_check 
CHECK (duration_minutes > 0 AND duration_minutes <= 180);

-- Function to auto-complete matches after duration
CREATE OR REPLACE FUNCTION auto_complete_match()
RETURNS void AS $$
BEGIN
  UPDATE public.matches
  SET status = 'completed',
      completed_at = NOW()
  WHERE status IN ('in_progress', 'open')
    AND match_date + (duration_minutes || ' minutes')::INTERVAL < NOW();
END;
$$ LANGUAGE plpgsql;
