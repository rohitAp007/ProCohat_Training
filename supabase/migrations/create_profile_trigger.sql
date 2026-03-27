-- ============================================================================
-- AUTO-CREATE PROFILE ON USER SIGNUP
-- ============================================================================
-- This trigger automatically creates a profile when a new user signs up
-- ============================================================================

-- Function to create profile for new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insert new profile using phone number from auth metadata
  INSERT INTO public.profiles (
    id,
    user_id,
    full_name,
    bio,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    NEW.id,  -- user_id same as id
    COALESCE(NEW.phone, 'User ' || SUBSTRING(NEW.id::TEXT, 1, 8)),
    'Hey there! I am using ProCohat',
    NOW(),
    NOW()
  );
  
  RETURN NEW;
END;
$$;

-- Trigger to auto-create profile when user authenticates
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO service_role;
GRANT ALL ON public.profiles TO service_role;

COMMENT ON FUNCTION handle_new_user() IS 'Automatically creates a profile when a new user signs up';

-- Test query (optional - to verify existing users have profiles)
-- Run this manually if needed to create profiles for existing users:
/*
INSERT INTO public.profiles (id, full_name, bio, created_at, updated_at)
SELECT 
  id,
  COALESCE(phone, 'User ' || SUBSTRING(id::TEXT, 1, 8)),
  'Hey there! I am using ProCohat',
  created_at,
  NOW()
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.profiles)
ON CONFLICT (id) DO NOTHING;
*/
