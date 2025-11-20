-- Diagnostic script to identify API 500 errors
-- Run this to check RLS policies and identify issues

-- ===========================================
-- 1. Check RLS Status on All Tables
-- ===========================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- ===========================================
-- 2. Check All RLS Policies
-- ===========================================

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    qual as policy_condition,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- ===========================================
-- 3. Test Users Table Access
-- ===========================================

-- Test 1: Can current user view their own profile?
-- SELECT * FROM users WHERE id = auth.uid();

-- Test 2: Can current user view other users?
-- SELECT id, name, email, avatar_url FROM users WHERE id != auth.uid() LIMIT 5;

-- Test 3: Can we join team_members with users?
-- SELECT tm.*, u.id, u.name FROM team_members tm
-- JOIN users u ON tm.user_id = u.id LIMIT 5;

-- ===========================================
-- 4. Check for Policy Conflicts
-- ===========================================

-- Find policies that might conflict
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    qual
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'users'
ORDER BY tablename, policyname;

-- ===========================================
-- 5. Check Team Members Policies
-- ===========================================

SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    qual
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename = 'team_members'
ORDER BY tablename, policyname;

-- ===========================================
-- 6. Check for Missing Indexes
-- ===========================================

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- ===========================================
-- 7. Check Table Constraints
-- ===========================================

SELECT 
    constraint_name,
    table_name,
    constraint_type
FROM information_schema.table_constraints
WHERE table_schema = 'public'
ORDER BY table_name, constraint_name;

-- ===========================================
-- 8. Check for Foreign Key Issues
-- ===========================================

SELECT 
    constraint_name,
    table_name,
    column_name,
    referenced_table_name,
    referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = 'public'
    AND referenced_table_name IS NOT NULL
ORDER BY table_name, constraint_name;

-- ===========================================
-- 9. Check Trigger Functions
-- ===========================================

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- ===========================================
-- 10. Performance Analysis
-- ===========================================

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ===========================================
-- Notes for Debugging
-- ===========================================

-- Common causes of 500 errors:
-- 1. RLS policy violations (most common)
-- 2. Foreign key constraint violations
-- 3. Trigger function errors
-- 4. Missing indexes causing timeouts
-- 5. Recursive policy checks
-- 6. Type mismatches in policy conditions

-- If you see 500 errors:
-- 1. Check the Supabase logs for the actual error message
-- 2. Run the test queries above to identify which policy is failing
-- 3. Look for recursive policy conditions
-- 4. Check for missing columns in policy conditions
-- 5. Verify foreign key relationships are correct
