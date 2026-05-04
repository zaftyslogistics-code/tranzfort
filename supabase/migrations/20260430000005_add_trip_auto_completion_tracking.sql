-- Add auto-completion tracking fields to trips table
-- This supports Task 13.5: Surface proof-submitted auto-completion rules in UI

-- Add auto-completion tracking columns
ALTER TABLE public.trips
ADD COLUMN IF NOT EXISTS auto_completion_enabled BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS auto_completion_expected_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS auto_completion_countdown_seconds INT,
ADD COLUMN IF NOT EXISTS supplier_confirmation_required BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS supplier_confirmation_deadline TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS supplier_confirmed_at TIMESTAMPTZ;

-- Create index for auto-completion queries
CREATE INDEX IF NOT EXISTS idx_trips_auto_completion ON public.trips(auto_completion_enabled, auto_completion_expected_at)
WHERE auto_completion_enabled = true;

-- Create index for supplier confirmation queries
CREATE INDEX IF NOT EXISTS idx_trips_supplier_confirmation ON public.trips(supplier_confirmation_required, supplier_confirmation_deadline)
WHERE supplier_confirmation_required = true;

-- Function to enable auto-completion after POD upload
CREATE OR REPLACE FUNCTION public.enable_trip_auto_completion(
  p_trip_id UUID,
  p_completion_window_hours INT DEFAULT 24
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_trip RECORD;
  v_expected_at TIMESTAMPTZ;
  v_countdown_seconds INT;
BEGIN
  -- Fetch trip and verify stage
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found');
  END IF;

  IF v_trip.stage NOT IN ('delivered', 'pod_uploaded') THEN
    RETURN jsonb_build_object('error', 'Trip must be in delivered or pod_uploaded stage');
  END IF;

  IF v_trip.pod_document_path IS NULL OR v_trip.pod_document_path = '' THEN
    RETURN jsonb_build_object('error', 'POD must be uploaded before enabling auto-completion');
  END IF;

  -- Calculate expected completion time
  v_expected_at := NOW() + (p_completion_window_hours || ' hours')::INTERVAL;
  v_countdown_seconds := p_completion_window_hours * 3600;

  -- Update trip with auto-completion settings
  UPDATE public.trips
  SET
    auto_completion_enabled = true,
    auto_completion_expected_at = v_expected_at,
    auto_completion_countdown_seconds = v_countdown_seconds,
    supplier_confirmation_required = true,
    supplier_confirmation_deadline = v_expected_at,
    updated_at = NOW()
  WHERE id = p_trip_id;

  RETURN jsonb_build_object(
    'success', true,
    'trip_id', p_trip_id,
    'auto_completion_enabled', true,
    'auto_completion_expected_at', v_expected_at,
    'auto_completion_countdown_seconds', v_countdown_seconds,
    'supplier_confirmation_required', true,
    'supplier_confirmation_deadline', v_expected_at
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.enable_trip_auto_completion(UUID, INT) TO authenticated;

-- Function to confirm trip by supplier (stops auto-completion)
CREATE OR REPLACE FUNCTION public.confirm_trip_by_supplier(
  p_trip_id UUID,
  p_supplier_id UUID
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_trip RECORD;
BEGIN
  -- Fetch trip and verify ownership
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id AND supplier_id = p_supplier_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found or access denied');
  END IF;

  IF NOT v_trip.supplier_confirmation_required THEN
    RETURN jsonb_build_object('error', 'Supplier confirmation not required for this trip');
  END IF;

  IF v_trip.supplier_confirmed_at IS NOT NULL THEN
    RETURN jsonb_build_object('error', 'Trip already confirmed by supplier');
  END IF;

  -- Update trip confirmation
  UPDATE public.trips
  SET
    supplier_confirmed_at = NOW(),
    auto_completion_enabled = false, -- Disable auto-completion after confirmation
    updated_at = NOW()
  WHERE id = p_trip_id;

  RETURN jsonb_build_object(
    'success', true,
    'trip_id', p_trip_id,
    'supplier_confirmed_at', NOW(),
    'auto_completion_enabled', false
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.confirm_trip_by_supplier(UUID, UUID) TO authenticated;

-- Function to get auto-completion status for a trip
CREATE OR REPLACE FUNCTION public.get_trip_auto_completion_status(p_trip_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_trip RECORD;
  v_remaining_seconds INT;
  v_status TEXT;
BEGIN
  -- Fetch trip
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'Trip not found');
  END IF;

  -- Calculate remaining time
  IF v_trip.auto_completion_enabled AND v_trip.auto_completion_expected_at IS NOT NULL THEN
    v_remaining_seconds := EXTRACT(EPOCH FROM (v_trip.auto_completion_expected_at - NOW()))::INT;
    
    IF v_remaining_seconds <= 0 THEN
      v_status := 'expired';
      v_remaining_seconds := 0;
    ELSIF v_remaining_seconds < 3600 THEN
      v_status := 'urgent'; -- Less than 1 hour
    ELSE
      v_status := 'active';
    END IF;
  ELSE
    v_remaining_seconds := 0;
    v_status := 'not_enabled';
  END IF;

  RETURN jsonb_build_object(
    'trip_id', p_trip_id,
    'auto_completion_enabled', v_trip.auto_completion_enabled,
    'auto_completion_expected_at', v_trip.auto_completion_expected_at,
    'auto_completion_countdown_seconds', v_trip.auto_completion_countdown_seconds,
    'remaining_seconds', v_remaining_seconds,
    'status', v_status,
    'supplier_confirmation_required', v_trip.supplier_confirmation_required,
    'supplier_confirmation_deadline', v_trip.supplier_confirmation_deadline,
    'supplier_confirmed_at', v_trip.supplier_confirmed_at,
    'can_confirm', v_trip.supplier_confirmation_required AND v_trip.supplier_confirmed_at IS NULL
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_trip_auto_completion_status(UUID) TO authenticated;

-- Function to auto-complete expired trips (to be called by cron/scheduler)
CREATE OR REPLACE FUNCTION public.auto_complete_expired_trips()
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_completed_count INT DEFAULT 0;
BEGIN
  -- Auto-complete trips where:
  -- 1. Auto-completion is enabled
  -- 2. Expected time has passed
  -- 3. Supplier has not confirmed
  -- 4. Stage is delivered or pod_uploaded
  UPDATE public.trips
  SET
    stage = 'completed',
    completed_at = COALESCE(completed_at, NOW()),
    auto_completion_enabled = false,
    updated_at = NOW()
  WHERE
    auto_completion_enabled = true
    AND auto_completion_expected_at IS NOT NULL
    AND auto_completion_expected_at <= NOW()
    AND supplier_confirmed_at IS NULL
    AND stage IN ('delivered', 'pod_uploaded');

  GET DIAGNOSTICS v_completed_count = ROW_COUNT;

  RETURN jsonb_build_object(
    'success', true,
    'completed_count', v_completed_count,
    'timestamp', NOW()
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.auto_complete_expired_trips() TO authenticated;
