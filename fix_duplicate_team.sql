-- Fix duplicate team issue for GROUPENIYA1
-- Run this in Supabase SQL Editor

-- Step 1: Check if team exists
SELECT 
    id, 
    name, 
    owner_id, 
    created_at,
    (SELECT email FROM auth.users WHERE id = owner_id) as owner_email
FROM teams 
WHERE LOWER(TRIM(name)) = 'groupeniya1';

-- Step 2: If team exists and belongs to current user, delete it
-- (Uncomment and run if needed)
/*
DELETE FROM teams 
WHERE LOWER(TRIM(name)) = 'groupeniya1'
AND owner_id = auth.uid();
*/

-- Step 3: Verify constraints
SELECT 
    conname AS constraint_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE conrelid = 'public.teams'::regclass
AND conname LIKE '%name%';

-- Expected result: Only 'unique_team_owner_name' should exist
-- 'unique_team_name' should NOT exist
