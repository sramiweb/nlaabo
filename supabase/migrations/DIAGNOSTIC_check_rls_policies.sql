-- Diagnostic Script: Check RLS Policies for Leave Match/Team Issue
-- Run this in Supabase SQL Editor to diagnose the problem

-- ============================================
-- 1. CHECK CURRENT RLS POLICIES
-- ============================================

-- Check team_members policies
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
WHERE tablename = 'team_members'
ORDER BY policyname;

-- Check match_participants policies
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
WHERE tablename = 'match_participants'
ORDER BY policyname;

-- ============================================
-- 2. CHECK IF USER CAN DELETE THEIR OWN RECORDS
-- ============================================

-- Test query for team_members (replace USER_ID and TEAM_ID with actual values)
-- This simulates what happens when a user tries to leave a team
DO $$
DECLARE
    test_user_id UUID := 'YOUR_USER_ID_HERE';  -- Replace with actual user ID
    test_team_id UUID := 'YOUR_TEAM_ID_HERE';  -- Replace with actual team ID
    can_delete BOOLEAN;
BEGIN
    -- Check if the user can delete their own team membership
    SELECT EXISTS (
        SELECT 1 FROM public.team_members
        WHERE team_id = test_team_id 
        AND user_id = test_user_id
    ) INTO can_delete;
    
    RAISE NOTICE 'User membership exists: %', can_delete;
    
    -- Try to simulate the delete check
    RAISE NOTICE 'Checking RLS policy...';
    RAISE NOTICE 'User ID: %', test_user_id;
    RAISE NOTICE 'Team ID: %', test_team_id;
END $$;

-- ============================================
-- 3. CHECK FOR BLOCKING TRIGGERS
-- ============================================

-- Check triggers on team_members
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'team_members'
ORDER BY trigger_name;

-- Check triggers on match_participants
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement,
    action_timing
FROM information_schema.triggers
WHERE event_object_table = 'match_participants'
ORDER BY trigger_name;

-- ============================================
-- 4. CHECK CURRENT TEAM MEMBERS
-- ============================================

-- Show all team members (to verify data exists)
SELECT 
    tm.id,
    tm.team_id,
    tm.user_id,
    tm.role,
    t.name as team_name,
    t.owner_id,
    u.name as user_name
FROM public.team_members tm
JOIN public.teams t ON tm.team_id = t.id
JOIN public.users u ON tm.user_id = u.id
ORDER BY t.name, tm.joined_at;

-- ============================================
-- 5. CHECK CURRENT MATCH PARTICIPANTS
-- ============================================

-- Show all match participants (to verify data exists)
SELECT 
    mp.id,
    mp.match_id,
    mp.user_id,
    mp.status,
    m.title as match_title,
    u.name as user_name
FROM public.match_participants mp
JOIN public.matches m ON mp.match_id = m.id
JOIN public.users u ON mp.user_id = u.id
ORDER BY m.match_date DESC, mp.joined_at;

-- ============================================
-- 6. SUMMARY
-- ============================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'DIAGNOSTIC COMPLETE';
    RAISE NOTICE '============================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Review the results above to identify:';
    RAISE NOTICE '1. Current RLS policies on team_members and match_participants';
    RAISE NOTICE '2. Whether the policies allow self-deletion (auth.uid() = user_id)';
    RAISE NOTICE '3. Any triggers that might be blocking deletes';
    RAISE NOTICE '4. Current data in the tables';
    RAISE NOTICE '';
    RAISE NOTICE 'Expected policy for team_members DELETE:';
    RAISE NOTICE '  - Should include: auth.uid() = user_id';
    RAISE NOTICE '';
    RAISE NOTICE 'Expected policy for match_participants DELETE:';
    RAISE NOTICE '  - Should include: auth.uid() = user_id';
END $$;
