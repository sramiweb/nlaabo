-- Verify RLS policies are correctly applied
SELECT 
    policyname,
    permissive,
    roles,
    qual as policy_condition
FROM pg_policies
WHERE schemaname = 'public' AND tablename = 'users'
ORDER BY policyname;
