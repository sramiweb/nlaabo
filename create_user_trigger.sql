-- Create trigger to automatically create user profile on auth signup
-- Run this in Supabase SQL Editor

-- Function to handle new user creation with conflict resolution
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
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
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

DROP TRIGGER IF EXISTS on_auth_user_metadata_updated ON auth.users;
CREATE TRIGGER on_auth_user_metadata_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_metadata_update();