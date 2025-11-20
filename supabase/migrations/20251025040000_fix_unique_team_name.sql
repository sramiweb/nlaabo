-- Drop the existing constraint if it exists
ALTER TABLE teams DROP CONSTRAINT IF EXISTS unique_team_name;

-- Remove duplicates by keeping the first team per name (ordered by id)
WITH duplicates AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) AS rn
    FROM teams
)
DELETE FROM teams WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- Add the unique constraint back
ALTER TABLE teams ADD CONSTRAINT unique_team_name UNIQUE (name);