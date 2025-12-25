-- Fix recursive admin policy check
-- This migration fixes the infinite recursion caused by policies querying the users table
-- to check for admin status while the users table itself has policies.

-- 1. Create a secure function to check admin status (SECURITY DEFINER bypasses RLS)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.users
        WHERE id = auth.uid()
        AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Drop the recursive policies
DROP POLICY IF EXISTS "Users can view own profile and admins can view all" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile, admins can update all" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "Users can view own notifications and admins can view all" ON public.notifications;
DROP POLICY IF EXISTS "Admins can delete notifications" ON public.notifications;

-- 3. Recreate policies using the safe function

-- Users policies
CREATE POLICY "Users can view own profile and admins can view all" ON public.users
    FOR SELECT USING (
        auth.uid() = id OR
        public.is_admin()
    );

CREATE POLICY "Users can update own profile, admins can update all" ON public.users
    FOR UPDATE USING (
        auth.uid() = id OR
        public.is_admin()
    );

CREATE POLICY "Admins can delete users" ON public.users
    FOR DELETE USING (
        public.is_admin()
    );

-- Notifications policies
CREATE POLICY "Users can view own notifications and admins can view all" ON public.notifications
    FOR SELECT USING (
        auth.uid() = user_id OR
        public.is_admin()
    );

CREATE POLICY "Admins can delete notifications" ON public.notifications
    FOR DELETE USING (
        public.is_admin()
    );
