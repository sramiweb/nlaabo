-- First, handle duplicates by keeping the first team per name (assuming ordered by id)
WITH duplicates AS (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY name ORDER BY id) AS rn
    FROM teams
)
DELETE FROM teams WHERE id IN (
    SELECT id FROM duplicates WHERE rn > 1
);

-- Then add the unique constraint
ALTER TABLE teams ADD CONSTRAINT unique_team_name UNIQUE (name);