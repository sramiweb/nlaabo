-- Migration: Add missing user profile columns
-- Created: 2024
-- Description: Adds position, location, skill_level, and bio columns to users table

-- Add position column (football position like Gardien, Défenseur, Milieu, Attaquant)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS position TEXT;

-- Add location column (city/location)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS location TEXT;

-- Add skill_level column (beginner, intermediate, advanced)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS skill_level TEXT 
CHECK (skill_level IN ('beginner', 'intermediate', 'advanced') OR skill_level IS NULL);

-- Add bio column (user biography/description)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS bio TEXT;

-- Add comments for documentation
COMMENT ON COLUMN users.position IS 'Football position (e.g., Gardien, Défenseur, Milieu, Attaquant)';
COMMENT ON COLUMN users.location IS 'User city/location';
COMMENT ON COLUMN users.skill_level IS 'Skill level: beginner, intermediate, or advanced';
COMMENT ON COLUMN users.bio IS 'User biography/description (max 200 characters)';

-- Create indexes for frequently queried columns
CREATE INDEX IF NOT EXISTS idx_users_location ON users(location);
CREATE INDEX IF NOT EXISTS idx_users_skill_level ON users(skill_level);
CREATE INDEX IF NOT EXISTS idx_users_position ON users(position);

-- Refresh PostgREST schema cache
NOTIFY pgrst, 'reload schema';
