CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_full_name TEXT;
  v_email TEXT;
  v_mobile TEXT;
BEGIN
  v_full_name := COALESCE(
    NULLIF(BTRIM(COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', '')), ''),
    NULLIF(BTRIM(SPLIT_PART(COALESCE(NEW.email, ''), '@', 1)), ''),
    'User'
  );
  v_email := NULLIF(BTRIM(COALESCE(NEW.email, '')), '');
  v_mobile := NULLIF(BTRIM(COALESCE(NEW.phone, '')), '');

  INSERT INTO public.profiles (id, full_name, email, mobile)
  VALUES (
    NEW.id,
    v_full_name,
    v_email,
    v_mobile
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
