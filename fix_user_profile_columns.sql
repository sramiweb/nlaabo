-- ============================================
-- FIX: Add Missing User Profile Columns
-- ============================================
-- Run this in Supabase SQL Editor to fix PGRST204 error
-- This adds: position, location, skill_level, bio columns

BEGIN;

-- 1. Add position column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS position TEXT;

-- 2. Add location column  
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS location TEXT;

-- 3. Add skill_level column with constraint
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS skill_level TEXT;

-- Add constraint separately to avoid issues if column exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'users_skill_level_check'
    ) THEN
        ALTER TABLE users 
        ADD CONSTRAINT users_skill_level_check 
        CHECK (skill_level IN ('beginner', 'intermediate', 'advanced') OR skill_level IS NULL);
    END IF;
END $$;

-- 4. Add bio column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- 5. Add column comments
COMMENT ON COLUMN users.position IS 'Football position (Gardien, Défenseur, Milieu, Attaquant)';
COMMENT ON COLUMN users.location IS 'User city/location';
COMMENT ON COLUMN users.skill_level IS 'Skill level: beginner, intermediate, or advanced';
COMMENT ON COLUMN users.bio IS 'User biography (max 200 characters)';

-- 6. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location);
CREATE INDEX IF NOT EXISTS idx_users_skill_level ON users(skill_level);
CREATE INDEX IF NOT EXISTS idx_users_position ON users(position);

-- 7. Verify columns exist
DO $$
DECLARE
    missing_cols TEXT[];
BEGIN
    SELECT ARRAY_AGG(col) INTO missing_cols
    FROM (VALUES ('position'), ('location'), ('skill_level'), ('bio')) AS cols(col)
    WHERE NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'users' AND column_name = cols.col
    );
    
    IF missing_cols IS NOT NULL THEN
        RAISE EXCEPTION 'Missing columns: %', array_to_string(missing_cols, ', ');
    ELSE
        RAISE NOTICE 'All columns added successfully!';
    END IF;
END $$;

COMMIT;

-- 8. Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';

-- 9. Verification query
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('position', 'location', 'skill_level', 'bio', 'name', 'email', 'phone', 'age', 'gender')
ORDER BY column_name;
