-- Fix users role constraint to match the original schema
-- The constraint should allow: player, coach, admin

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

-- Log the fix
DO $$
BEGIN
    RAISE NOTICE '✅ Users role constraint fixed';
    RAISE NOTICE 'Valid roles: player, coach, admin';
END $$;
