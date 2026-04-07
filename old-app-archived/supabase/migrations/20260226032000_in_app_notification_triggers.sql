-- Keyless-first notification triggers (free-tier friendly)
-- Strategy: always create in-app notifications in DB.
-- FCM/push delivery can be layered later via Edge Functions once keys are available.

CREATE OR REPLACE FUNCTION public.create_in_app_notification(
  p_user_id UUID,
  p_title TEXT,
  p_body TEXT,
  p_type TEXT,
  p_data JSONB DEFAULT '{}'::jsonb
) RETURNS VOID AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RETURN;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (p_user_id, p_title, p_body, p_type, COALESCE(p_data, '{}'::jsonb));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1) Trucker books load -> Supplier gets notification
CREATE OR REPLACE FUNCTION public.notify_on_booking_request()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.parent_load_id IS NOT NULL AND NEW.status = 'pending_approval' THEN
    PERFORM public.create_in_app_notification(
      NEW.supplier_id,
      'New Booking Request',
      'A trucker requested booking for your load.',
      'booking_new',
      jsonb_build_object('load_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_booking_request ON public.loads;
CREATE TRIGGER trg_notify_on_booking_request
AFTER INSERT ON public.loads
FOR EACH ROW
EXECUTE FUNCTION public.notify_on_booking_request();

-- 2) Supplier approves/rejects booking -> Trucker gets notification
CREATE OR REPLACE FUNCTION public.notify_on_booking_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status = 'pending_approval' AND NEW.status = 'booked' THEN
    PERFORM public.create_in_app_notification(
      NEW.assigned_trucker_id,
      'Booking Approved!',
      'Your booking request was approved.',
      'booking_approved',
      jsonb_build_object('load_id', NEW.id)
    );
  ELSIF OLD.status = 'pending_approval' AND NEW.status = 'cancelled' THEN
    PERFORM public.create_in_app_notification(
      NEW.assigned_trucker_id,
      'Booking Rejected',
      'Your booking request was rejected.',
      'booking_rejected',
      jsonb_build_object('load_id', NEW.id)
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_booking_status_change ON public.loads;
CREATE TRIGGER trg_notify_on_booking_status_change
AFTER UPDATE ON public.loads
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION public.notify_on_booking_status_change();

-- 3) Verification status updates -> User gets notification
CREATE OR REPLACE FUNCTION public.notify_on_verification_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.verification_status IS DISTINCT FROM NEW.verification_status THEN
    IF NEW.verification_status = 'verified' THEN
      PERFORM public.create_in_app_notification(
        NEW.id,
        'Account Verified',
        'Your account verification is complete.',
        'verification_done',
        '{}'::jsonb
      );
    ELSIF NEW.verification_status = 'rejected' THEN
      PERFORM public.create_in_app_notification(
        NEW.id,
        'Verification Failed',
        COALESCE(NEW.verification_rejection_reason, 'Please review and re-submit your documents.'),
        'verification_failed',
        jsonb_build_object('reason', NEW.verification_rejection_reason)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_verification_change ON public.profiles;
CREATE TRIGGER trg_notify_on_verification_change
AFTER UPDATE ON public.profiles
FOR EACH ROW
WHEN (OLD.verification_status IS DISTINCT FROM NEW.verification_status)
EXECUTE FUNCTION public.notify_on_verification_change();

-- 4) POD uploaded -> Supplier gets notification
CREATE OR REPLACE FUNCTION public.notify_on_trip_stage_change()
RETURNS TRIGGER AS $$
DECLARE
  v_supplier_id UUID;
BEGIN
  IF OLD.stage IS DISTINCT FROM NEW.stage THEN
    SELECT supplier_id INTO v_supplier_id
    FROM public.loads
    WHERE id = NEW.load_id;

    IF NEW.stage = 'pod_uploaded' THEN
      PERFORM public.create_in_app_notification(
        v_supplier_id,
        'Proof of Delivery Uploaded',
        'POD was uploaded for your load.',
        'pod_uploaded',
        jsonb_build_object('load_id', NEW.load_id, 'trip_id', NEW.id)
      );
    ELSIF NEW.stage = 'completed' THEN
      PERFORM public.create_in_app_notification(
        NEW.trucker_id,
        'Delivery Confirmed',
        'Supplier confirmed delivery completion.',
        'delivery_confirmed',
        jsonb_build_object('load_id', NEW.load_id, 'trip_id', NEW.id)
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_on_trip_stage_change ON public.trips;
CREATE TRIGGER trg_notify_on_trip_stage_change
AFTER UPDATE ON public.trips
FOR EACH ROW
WHEN (OLD.stage IS DISTINCT FROM NEW.stage)
EXECUTE FUNCTION public.notify_on_trip_stage_change();
