-- Fix duplicate key constraint issues in auth flow
-- This migration addresses issues with user profile creation conflicts

-- Remove unique constraint on email in users table since auth.users handles email uniqueness
-- This prevents conflicts when the trigger tries to create profiles for existing auth users
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_email_unique;
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_email_key;

-- Update the user creation trigger to handle conflicts gracefully
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS public.handle_user_metadata_update();

-- Enhanced function to handle new user creation with conflict resolution
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create profile if it doesn't already exist
  INSERT INTO public.users (id, email, name, role, gender, age, phone, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'role', 'player'),
    NEW.raw_user_meta_data->>'gender',
    CASE
      WHEN NEW.raw_user_meta_data->>'age' IS NOT NULL
      THEN (NEW.raw_user_meta_data->>'age')::INTEGER
      ELSE NULL
    END,
    NEW.raw_user_meta_data->>'phone',
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    -- Update existing profile with new metadata if provided
    name = COALESCE(NEW.raw_user_meta_data->>'name', public.users.name),
    email = NEW.email,
    role = COALESCE(NEW.raw_user_meta_data->>'role', public.users.role),
    gender = COALESCE(NEW.raw_user_meta_data->>'gender', public.users.gender),
    age = COALESCE(
      CASE
        WHEN NEW.raw_user_meta_data->>'age' IS NOT NULL
        THEN (NEW.raw_user_meta_data->>'age')::INTEGER
        ELSE NULL
      END,
      public.users.age
    ),
    phone = COALESCE(NEW.raw_user_meta_data->>'phone', public.users.phone),
    updated_at = NOW();

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to call the function after user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Also handle updates to user metadata
CREATE OR REPLACE FUNCTION public.handle_user_metadata_update()
RETURNS TRIGGER AS $$
BEGIN
  -- Update user profile when auth metadata changes
  UPDATE public.users
  SET
    name = COALESCE(NEW.raw_user_meta_data->>'name', public.users.name),
    role = COALESCE(NEW.raw_user_meta_data->>'role', public.users.role),
    gender = COALESCE(NEW.raw_user_meta_data->>'gender', public.users.gender),
    age = COALESCE(
      CASE
        WHEN NEW.raw_user_meta_data->>'age' IS NOT NULL
        THEN (NEW.raw_user_meta_data->>'age')::INTEGER
        ELSE NULL
      END,
      public.users.age
    ),
    phone = COALESCE(NEW.raw_user_meta_data->>'phone', public.users.phone),
    updated_at = NOW()
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_metadata_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_metadata_update();

-- Add policy to allow the trigger function to create/update profiles
CREATE POLICY "Service role can manage all profiles" ON public.users
    FOR ALL USING (auth.role() = 'service_role');

-- Update RLS policies to be more robust
DROP POLICY IF EXISTS "Users can create own profile" ON public.users;
CREATE POLICY "Users can create own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Ensure proper indexes exist
DROP INDEX IF EXISTS idx_users_email;
CREATE INDEX idx_users_email ON public.users(email); -- For email lookups (non-unique)

-- Success message
DO $$
BEGIN
    RAISE NOTICE 'Auth duplicate constraint fixes applied successfully!';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '1. Removed unique constraint on users.email';
    RAISE NOTICE '2. Updated trigger to handle conflicts gracefully';
    RAISE NOTICE '3. Added metadata update trigger';
    RAISE NOTICE '4. Enhanced RLS policies';
    RAISE NOTICE '';
    RAISE NOTICE 'Next steps:';
    RAISE NOTICE '1. Test signup with existing email addresses';
    RAISE NOTICE '2. Verify profile creation works correctly';
    RAISE NOTICE '3. Check that login still works for existing users';
END $$;