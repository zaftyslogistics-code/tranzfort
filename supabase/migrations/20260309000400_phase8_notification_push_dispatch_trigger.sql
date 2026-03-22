CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

CREATE OR REPLACE FUNCTION dispatch_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  v_push_url TEXT;
BEGIN
  IF NEW.target_profile_id IS NULL THEN
    RETURN NEW;
  END IF;

  v_push_url := COALESCE(
    NULLIF(current_setting('app.settings.push_edge_function_url', true), ''),
    'https://jgtgdfhdtjhidywpautk.supabase.co/functions/v1/send-push-notification'
  );
  IF btrim(v_push_url) = '' THEN
    RETURN NEW;
  END IF;

  PERFORM net.http_post(
    url := v_push_url,
    headers := '{"Content-Type": "application/json"}'::jsonb,
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_dispatch_push_notification ON notifications;

CREATE TRIGGER trg_dispatch_push_notification
AFTER INSERT ON notifications
FOR EACH ROW
EXECUTE FUNCTION dispatch_push_notification();
