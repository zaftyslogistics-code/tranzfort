-- P0-4: Require shared dispatch secret between DB trigger and push edge function.
-- Operator setup (once per environment):
--   1. supabase secrets set PUSH_DISPATCH_SECRET=<random-32+>
--   2. ALTER DATABASE postgres SET app.settings.push_dispatch_secret = '<same-value>';

CREATE OR REPLACE FUNCTION public.dispatch_push_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_push_url TEXT;
  v_secret TEXT;
  v_headers JSONB;
BEGIN
  IF NEW.target_profile_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_secret := NULLIF(btrim(current_setting('app.settings.push_dispatch_secret', true)), '');
  IF v_secret IS NULL THEN
    RETURN NEW;
  END IF;

  v_push_url := COALESCE(
    NULLIF(current_setting('app.settings.push_edge_function_url', true), ''),
    'https://jgtgdfhdtjhidywpautk.supabase.co/functions/v1/send-push-notification'
  );
  IF btrim(v_push_url) = '' THEN
    RETURN NEW;
  END IF;

  v_headers := jsonb_build_object(
    'Content-Type', 'application/json',
    'x-push-dispatch-secret', v_secret
  );

  PERFORM net.http_post(
    url := v_push_url,
    headers := v_headers,
    body := jsonb_build_object(
      'target_user_id', NEW.target_profile_id,
      'title', COALESCE(NULLIF(NEW.title_text, ''), 'New notification'),
      'body', COALESCE(NEW.body_text, ''),
      'data', jsonb_strip_nulls(
        jsonb_build_object(
          'action_route_hint', NEW.action_route_hint,
          'related_load_id', NEW.related_load_id,
          'related_trip_id', NEW.related_trip_id,
          'related_case_id', NEW.related_case_id,
          'notification_type', NEW.notification_type,
          'notification_priority', NEW.notification_priority,
          'notification_id', NEW.id
        )
      )
    )
  );

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.dispatch_push_notification IS
  'Dispatches FCM push via edge function. Requires app.settings.push_dispatch_secret and edge PUSH_DISPATCH_SECRET.';
