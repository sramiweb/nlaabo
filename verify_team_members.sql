-- Verify team members setup and data
-- Run this in Supabase SQL Editor to diagnose the issue

-- 1. Check if add_team_member_safe function exists
SELECT 
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_team_member_safe';

-- 2. Check team_members table structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'team_members'
ORDER BY ordinal_position;

-- 3. Check RLS policies on team_members
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'team_members';

-- 4. Count team members for all teams
SELECT 
    t.id as team_id,
    t.name as team_name,
    COUNT(tm.id) as member_count
FROM public.teams t
LEFT JOIN public.team_members tm ON t.id = tm.team_id
WHERE t.deleted_at IS NULL
GROUP BY t.id, t.name
ORDER BY t.created_at DESC;

-- 5. Check recent join requests and their status
SELECT 
    jr.id,
    jr.team_id,
    jr.user_id,
    jr.status,
    jr.created_at,
    t.name as team_name,
    u.name as user_name
FROM public.team_join_requests jr
JOIN public.teams t ON jr.team_id = t.id
JOIN public.users u ON jr.user_id = u.id
ORDER BY jr.created_at DESC
LIMIT 10;
