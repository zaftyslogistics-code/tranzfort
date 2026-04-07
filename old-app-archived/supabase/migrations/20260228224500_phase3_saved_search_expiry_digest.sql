-- Phase 3 backend additions: saved searches, document expiry tracking, digest batching.

-- 1) Document expiry fields
ALTER TABLE public.truckers
ADD COLUMN IF NOT EXISTS dl_expiry_date DATE;

ALTER TABLE public.trucks
ADD COLUMN IF NOT EXISTS rc_expiry_date DATE;

CREATE INDEX IF NOT EXISTS idx_truckers_dl_expiry ON public.truckers(dl_expiry_date);
CREATE INDEX IF NOT EXISTS idx_trucks_rc_expiry ON public.trucks(rc_expiry_date);

-- 2) Saved searches for truckers
CREATE TABLE IF NOT EXISTS public.user_saved_searches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  origin_city TEXT,
  destination_city TEXT,
  material TEXT,
  truck_type TEXT,
  sort_by TEXT NOT NULL DEFAULT 'newest',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_saved_searches_user
  ON public.user_saved_searches(user_id, updated_at DESC);

ALTER TABLE public.user_saved_searches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own saved searches" ON public.user_saved_searches;
CREATE POLICY "Users can view their own saved searches"
ON public.user_saved_searches
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own saved searches" ON public.user_saved_searches;
CREATE POLICY "Users can insert their own saved searches"
ON public.user_saved_searches
FOR INSERT
WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own saved searches" ON public.user_saved_searches;
CREATE POLICY "Users can delete their own saved searches"
ON public.user_saved_searches
FOR DELETE
USING (auth.uid() = user_id);

-- 3) Document expiry warning notifications (30-day window)
CREATE OR REPLACE FUNCTION public.notify_document_expiry_updates()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF TG_TABLE_NAME = 'truckers' THEN
    IF NEW.dl_expiry_date IS NOT NULL
      AND NEW.dl_expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
      AND (OLD IS NULL OR OLD.dl_expiry_date IS DISTINCT FROM NEW.dl_expiry_date) THEN
      INSERT INTO public.notifications (user_id, title, body, type, data)
      VALUES (
        NEW.id,
        'Driving licence expiry reminder',
        format('Your driving licence will expire on %s. Please renew it to avoid trip interruptions.', NEW.dl_expiry_date),
        'doc_expiry_warning',
        jsonb_build_object('doc', 'dl', 'expiry_date', NEW.dl_expiry_date)
      );
    END IF;
  ELSIF TG_TABLE_NAME = 'trucks' THEN
    IF NEW.rc_expiry_date IS NOT NULL
      AND NEW.rc_expiry_date BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
      AND (OLD IS NULL OR OLD.rc_expiry_date IS DISTINCT FROM NEW.rc_expiry_date) THEN
      INSERT INTO public.notifications (user_id, title, body, type, data)
      VALUES (
        NEW.owner_id,
        'RC expiry reminder',
        format('RC for truck %s will expire on %s. Please renew it in time.', COALESCE(NEW.truck_number, '-'), NEW.rc_expiry_date),
        'doc_expiry_warning',
        jsonb_build_object(
          'doc', 'rc',
          'truck_id', NEW.id,
          'truck_number', NEW.truck_number,
          'expiry_date', NEW.rc_expiry_date
        )
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_trucker_doc_expiry ON public.truckers;
CREATE TRIGGER trg_notify_trucker_doc_expiry
AFTER INSERT OR UPDATE OF dl_expiry_date
ON public.truckers
FOR EACH ROW
EXECUTE FUNCTION public.notify_document_expiry_updates();

DROP TRIGGER IF EXISTS trg_notify_truck_doc_expiry ON public.trucks;
CREATE TRIGGER trg_notify_truck_doc_expiry
AFTER INSERT OR UPDATE OF rc_expiry_date
ON public.trucks
FOR EACH ROW
EXECUTE FUNCTION public.notify_document_expiry_updates();

-- 4) Notification digest batching queue (route/type grouped, 30-minute cadence)
CREATE TABLE IF NOT EXISTS public.notification_digests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_key TEXT NOT NULL,
  route_label TEXT,
  digest_count INTEGER NOT NULL DEFAULT 1,
  sample_body TEXT,
  first_notification_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_notification_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  next_dispatch_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '30 minutes'),
  is_dispatched BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS uq_open_notification_digest
  ON public.notification_digests(user_id, route_key)
  WHERE is_dispatched = FALSE;

CREATE INDEX IF NOT EXISTS idx_notification_digests_ready
  ON public.notification_digests(is_dispatched, next_dispatch_at);

ALTER TABLE public.notification_digests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own notification digests" ON public.notification_digests;
CREATE POLICY "Users can view their own notification digests"
ON public.notification_digests
FOR SELECT
USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.enqueue_notification_digest()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_route_key TEXT;
  v_route_label TEXT;
BEGIN
  v_route_key := NULLIF(COALESCE(NEW.data->>'route_key', NEW.data->>'route', ''), '');
  v_route_label := NULLIF(COALESCE(NEW.data->>'route_label', NEW.data->>'route', ''), '');

  IF v_route_key IS NULL THEN
    v_route_key := NEW.type;
  END IF;

  INSERT INTO public.notification_digests (
    user_id,
    route_key,
    route_label,
    digest_count,
    sample_body,
    first_notification_at,
    last_notification_at,
    next_dispatch_at,
    is_dispatched,
    updated_at
  )
  VALUES (
    NEW.user_id,
    v_route_key,
    v_route_label,
    1,
    NEW.body,
    NEW.created_at,
    NEW.created_at,
    NEW.created_at + INTERVAL '30 minutes',
    FALSE,
    NOW()
  )
  ON CONFLICT (user_id, route_key) WHERE is_dispatched = FALSE
  DO UPDATE
  SET
    digest_count = public.notification_digests.digest_count + 1,
    sample_body = EXCLUDED.sample_body,
    last_notification_at = EXCLUDED.last_notification_at,
    next_dispatch_at = LEAST(
      public.notification_digests.next_dispatch_at,
      EXCLUDED.next_dispatch_at
    ),
    updated_at = NOW();

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enqueue_notification_digest ON public.notifications;
CREATE TRIGGER trg_enqueue_notification_digest
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.enqueue_notification_digest();

CREATE OR REPLACE FUNCTION public.get_ready_notification_digests(
  p_now TIMESTAMPTZ DEFAULT NOW()
)
RETURNS TABLE (
  id UUID,
  user_id UUID,
  route_key TEXT,
  route_label TEXT,
  digest_count INTEGER,
  sample_body TEXT,
  first_notification_at TIMESTAMPTZ,
  last_notification_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT
    d.id,
    d.user_id,
    d.route_key,
    d.route_label,
    d.digest_count,
    d.sample_body,
    d.first_notification_at,
    d.last_notification_at
  FROM public.notification_digests d
  WHERE d.is_dispatched = FALSE
    AND d.next_dispatch_at <= p_now
  ORDER BY d.next_dispatch_at ASC;
$$;

CREATE OR REPLACE FUNCTION public.mark_notification_digest_dispatched(
  p_digest_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.notification_digests
  SET is_dispatched = TRUE,
      updated_at = NOW()
  WHERE id = p_digest_id;
END;
$$;
