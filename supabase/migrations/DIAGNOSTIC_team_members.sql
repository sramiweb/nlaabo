-- Diagnostic script to check team_members table and policies

-- Check if team_members table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'team_members'
ORDER BY ordinal_position;

-- Check RLS policies on team_members
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'team_members';

-- Check if there are any team_members records
SELECT 
    tm.id,
    tm.team_id,
    tm.user_id,
    tm.role,
    tm.joined_at,
    t.name as team_name,
    u.name as user_name
FROM public.team_members tm
LEFT JOIN public.teams t ON tm.team_id = t.id
LEFT JOIN public.users u ON tm.user_id = u.id
ORDER BY tm.joined_at DESC
LIMIT 20;

-- Check for any pending join requests
SELECT 
    tjr.id,
    tjr.team_id,
    tjr.user_id,
    tjr.status,
    tjr.created_at,
    t.name as team_name,
    u.name as user_name
FROM public.team_join_requests tjr
LEFT JOIN public.teams t ON tjr.team_id = t.id
LEFT JOIN public.users u ON tjr.user_id = u.id
WHERE tjr.status = 'pending'
ORDER BY tjr.created_at DESC;

-- Check for approved join requests that might not have corresponding team_members
SELECT 
    tjr.id as request_id,
    tjr.team_id,
    tjr.user_id,
    tjr.status,
    tjr.created_at,
    t.name as team_name,
    u.name as user_name,
    CASE 
        WHEN tm.id IS NULL THEN 'MISSING TEAM MEMBER RECORD'
        ELSE 'Has team member record'
    END as member_status
FROM public.team_join_requests tjr
LEFT JOIN public.teams t ON tjr.team_id = t.id
LEFT JOIN public.users u ON tjr.user_id = u.id
LEFT JOIN public.team_members tm ON tm.team_id = tjr.team_id AND tm.user_id = tjr.user_id
WHERE tjr.status = 'approved'
ORDER BY tjr.created_at DESC
LIMIT 20;
