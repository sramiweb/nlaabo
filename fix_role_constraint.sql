-- Quick fix for users role constraint
-- Run this directly in Supabase SQL Editor

-- Drop the existing constraint
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;

-- Add the correct constraint
ALTER TABLE public.users 
ADD CONSTRAINT users_role_check 
CHECK (role IN ('player', 'coach', 'admin'));

-- Update any invalid roles to 'player' (default)
UPDATE public.users 
SET role = 'player' 
WHERE role NOT IN ('player', 'coach', 'admin');

SELECT '✅ Users role constraint fixed - Valid roles: player, coach, admin' AS status;
