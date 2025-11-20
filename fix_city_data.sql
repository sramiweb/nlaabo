-- Fix invalid city data in Supabase
-- This script removes cities with invalid IDs (null or invalid UUIDs)

-- First, check what invalid cities exist
SELECT id, name, country
FROM cities
WHERE id IS NULL;

-- Delete invalid cities (only null IDs since ID is UUID)
DELETE FROM cities
WHERE id IS NULL;

-- Verify the cleanup
SELECT COUNT(*) as total_cities,
       COUNT(CASE WHEN id IS NULL THEN 1 END) as invalid_cities
FROM cities;

-- Optional: Add a constraint to prevent future null IDs
-- ALTER TABLE cities ADD CONSTRAINT cities_id_not_null CHECK (id IS NOT NULL);