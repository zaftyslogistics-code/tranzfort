-- Create notification_preferences table to support per-category toggles, expiry, delivery state, and channel preference
-- This allows users to customize which notifications they receive and how

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  
  -- Per-category toggles
  load_booking_enabled BOOLEAN NOT NULL DEFAULT true,
  load_status_updates_enabled BOOLEAN NOT NULL DEFAULT true,
  trip_updates_enabled BOOLEAN NOT NULL DEFAULT true,
  chat_messages_enabled BOOLEAN NOT NULL DEFAULT true,
  review_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  support_responses_enabled BOOLEAN NOT NULL DEFAULT true,
  system_notifications_enabled BOOLEAN NOT NULL DEFAULT true,
  
  -- Channel preference
  push_enabled BOOLEAN NOT NULL DEFAULT true,
  in_app_enabled BOOLEAN NOT NULL DEFAULT true,
  email_enabled BOOLEAN NOT NULL DEFAULT false, -- Future: email notifications
  
  -- Quiet hours (time range when only urgent notifications should be delivered)
  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT false,
  quiet_hours_start TIME DEFAULT '22:00', -- 10 PM
  quiet_hours_end TIME DEFAULT '08:00', -- 8 AM
  quiet_hours_timezone TEXT DEFAULT 'Asia/Kolkata',
  
  -- Expiry settings (auto-dismiss old notifications)
  auto_dismiss_enabled BOOLEAN NOT NULL DEFAULT true,
  auto_dismiss_after_hours INT DEFAULT 24, -- Dismiss notifications after 24 hours
  
  -- Delivery state tracking
  delivery_tracking_enabled BOOLEAN NOT NULL DEFAULT true,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT notification_preferences_user_id_unique UNIQUE (user_id),
  CONSTRAINT notification_preferences_auto_dismiss_after_hours_check CHECK (auto_dismiss_after_hours >= 1),
  CONSTRAINT notification_preferences_quiet_hours_check CHECK (quiet_hours_start != quiet_hours_end)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notification_preferences_user_id ON public.notification_preferences(user_id);

-- Enable RLS
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view their own notification preferences" ON public.notification_preferences
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own notification preferences" ON public.notification_preferences
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own notification preferences" ON public.notification_preferences
  FOR UPDATE USING (user_id = auth.uid());

-- Grant permissions
GRANT ALL ON TABLE public.notification_preferences TO authenticated;

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_notification_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER notification_preferences_updated_at
BEFORE UPDATE ON public.notification_preferences
FOR EACH ROW
EXECUTE FUNCTION public.update_notification_preferences_updated_at();

-- Function to get notification preferences for a user
CREATE OR REPLACE FUNCTION public.get_notification_preferences(p_user_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_preferences JSONB;
BEGIN
  SELECT jsonb_build_object(
    'user_id', np.user_id,
    'load_booking_enabled', np.load_booking_enabled,
    'load_status_updates_enabled', np.load_status_updates_enabled,
    'trip_updates_enabled', np.trip_updates_enabled,
    'chat_messages_enabled', np.chat_messages_enabled,
    'review_notifications_enabled', np.review_notifications_enabled,
    'support_responses_enabled', np.support_responses_enabled,
    'system_notifications_enabled', np.system_notifications_enabled,
    'push_enabled', np.push_enabled,
    'in_app_enabled', np.in_app_enabled,
    'email_enabled', np.email_enabled,
    'quiet_hours_enabled', np.quiet_hours_enabled,
    'quiet_hours_start', np.quiet_hours_start,
    'quiet_hours_end', np.quiet_hours_end,
    'quiet_hours_timezone', np.quiet_hours_timezone,
    'auto_dismiss_enabled', np.auto_dismiss_enabled,
    'auto_dismiss_after_hours', np.auto_dismiss_after_hours,
    'delivery_tracking_enabled', np.delivery_tracking_enabled,
    'created_at', np.created_at,
    'updated_at', np.updated_at
  ) INTO v_preferences
  FROM public.notification_preferences np
  WHERE np.user_id = p_user_id;

  -- Return default preferences if not set
  IF v_preferences IS NULL THEN
    RETURN jsonb_build_object(
      'user_id', p_user_id,
      'load_booking_enabled', true,
      'load_status_updates_enabled', true,
      'trip_updates_enabled', true,
      'chat_messages_enabled', true,
      'review_notifications_enabled', true,
      'support_responses_enabled', true,
      'system_notifications_enabled', true,
      'push_enabled', true,
      'in_app_enabled', true,
      'email_enabled', false,
      'quiet_hours_enabled', false,
      'quiet_hours_start', '22:00',
      'quiet_hours_end', '08:00',
      'quiet_hours_timezone', 'Asia/Kolkata',
      'auto_dismiss_enabled', true,
      'auto_dismiss_after_hours', 24,
      'delivery_tracking_enabled', true,
      'created_at', NOW(),
      'updated_at', NOW()
    );
  END IF;

  RETURN v_preferences;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_notification_preferences(UUID) TO authenticated;

-- Function to update notification preferences
CREATE OR REPLACE FUNCTION public.update_notification_preferences(
  p_user_id UUID,
  p_load_booking_enabled BOOLEAN DEFAULT NULL,
  p_load_status_updates_enabled BOOLEAN DEFAULT NULL,
  p_trip_updates_enabled BOOLEAN DEFAULT NULL,
  p_chat_messages_enabled BOOLEAN DEFAULT NULL,
  p_review_notifications_enabled BOOLEAN DEFAULT NULL,
  p_support_responses_enabled BOOLEAN DEFAULT NULL,
  p_system_notifications_enabled BOOLEAN DEFAULT NULL,
  p_push_enabled BOOLEAN DEFAULT NULL,
  p_in_app_enabled BOOLEAN DEFAULT NULL,
  p_email_enabled BOOLEAN DEFAULT NULL,
  p_quiet_hours_enabled BOOLEAN DEFAULT NULL,
  p_quiet_hours_start TIME DEFAULT NULL,
  p_quiet_hours_end TIME DEFAULT NULL,
  p_quiet_hours_timezone TEXT DEFAULT NULL,
  p_auto_dismiss_enabled BOOLEAN DEFAULT NULL,
  p_auto_dismiss_after_hours INT DEFAULT NULL,
  p_delivery_tracking_enabled BOOLEAN DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_preferences JSONB;
BEGIN
  -- Upsert preferences
  INSERT INTO public.notification_preferences (
    user_id,
    load_booking_enabled,
    load_status_updates_enabled,
    trip_updates_enabled,
    chat_messages_enabled,
    review_notifications_enabled,
    support_responses_enabled,
    system_notifications_enabled,
    push_enabled,
    in_app_enabled,
    email_enabled,
    quiet_hours_enabled,
    quiet_hours_start,
    quiet_hours_end,
    quiet_hours_timezone,
    auto_dismiss_enabled,
    auto_dismiss_after_hours,
    delivery_tracking_enabled
  ) VALUES (
    p_user_id,
    COALESCE(p_load_booking_enabled, true),
    COALESCE(p_load_status_updates_enabled, true),
    COALESCE(p_trip_updates_enabled, true),
    COALESCE(p_chat_messages_enabled, true),
    COALESCE(p_review_notifications_enabled, true),
    COALESCE(p_support_responses_enabled, true),
    COALESCE(p_system_notifications_enabled, true),
    COALESCE(p_push_enabled, true),
    COALESCE(p_in_app_enabled, true),
    COALESCE(p_email_enabled, false),
    COALESCE(p_quiet_hours_enabled, false),
    COALESCE(p_quiet_hours_start, '22:00'),
    COALESCE(p_quiet_hours_end, '08:00'),
    COALESCE(p_quiet_hours_timezone, 'Asia/Kolkata'),
    COALESCE(p_auto_dismiss_enabled, true),
    COALESCE(p_auto_dismiss_after_hours, 24),
    COALESCE(p_delivery_tracking_enabled, true)
  )
  ON CONFLICT (user_id) DO UPDATE SET
    load_booking_enabled = COALESCE(EXCLUDED.load_booking_enabled, notification_preferences.load_booking_enabled),
    load_status_updates_enabled = COALESCE(EXCLUDED.load_status_updates_enabled, notification_preferences.load_status_updates_enabled),
    trip_updates_enabled = COALESCE(EXCLUDED.trip_updates_enabled, notification_preferences.trip_updates_enabled),
    chat_messages_enabled = COALESCE(EXCLUDED.chat_messages_enabled, notification_preferences.chat_messages_enabled),
    review_notifications_enabled = COALESCE(EXCLUDED.review_notifications_enabled, notification_preferences.review_notifications_enabled),
    support_responses_enabled = COALESCE(EXCLUDED.support_responses_enabled, notification_preferences.support_responses_enabled),
    system_notifications_enabled = COALESCE(EXCLUDED.system_notifications_enabled, notification_preferences.system_notifications_enabled),
    push_enabled = COALESCE(EXCLUDED.push_enabled, notification_preferences.push_enabled),
    in_app_enabled = COALESCE(EXCLUDED.in_app_enabled, notification_preferences.in_app_enabled),
    email_enabled = COALESCE(EXCLUDED.email_enabled, notification_preferences.email_enabled),
    quiet_hours_enabled = COALESCE(EXCLUDED.quiet_hours_enabled, notification_preferences.quiet_hours_enabled),
    quiet_hours_start = COALESCE(EXCLUDED.quiet_hours_start, notification_preferences.quiet_hours_start),
    quiet_hours_end = COALESCE(EXCLUDED.quiet_hours_end, notification_preferences.quiet_hours_end),
    quiet_hours_timezone = COALESCE(EXCLUDED.quiet_hours_timezone, notification_preferences.quiet_hours_timezone),
    auto_dismiss_enabled = COALESCE(EXCLUDED.auto_dismiss_enabled, notification_preferences.auto_dismiss_enabled),
    auto_dismiss_after_hours = COALESCE(EXCLUDED.auto_dismiss_after_hours, notification_preferences.auto_dismiss_after_hours),
    delivery_tracking_enabled = COALESCE(EXCLUDED.delivery_tracking_enabled, notification_preferences.delivery_tracking_enabled),
    updated_at = NOW()
  RETURNING jsonb_build_object(
    'user_id', user_id,
    'load_booking_enabled', load_booking_enabled,
    'load_status_updates_enabled', load_status_updates_enabled,
    'trip_updates_enabled', trip_updates_enabled,
    'chat_messages_enabled', chat_messages_enabled,
    'review_notifications_enabled', review_notifications_enabled,
    'support_responses_enabled', support_responses_enabled,
    'system_notifications_enabled', system_notifications_enabled,
    'push_enabled', push_enabled,
    'in_app_enabled', in_app_enabled,
    'email_enabled', email_enabled,
    'quiet_hours_enabled', quiet_hours_enabled,
    'quiet_hours_start', quiet_hours_start,
    'quiet_hours_end', quiet_hours_end,
    'quiet_hours_timezone', quiet_hours_timezone,
    'auto_dismiss_enabled', auto_dismiss_enabled,
    'auto_dismiss_after_hours', auto_dismiss_after_hours,
    'delivery_tracking_enabled', delivery_tracking_enabled,
    'created_at', created_at,
    'updated_at', updated_at
  ) INTO v_preferences;

  RETURN v_preferences;
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.update_notification_preferences(
  UUID, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN,
  BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, TIME, TIME, TEXT, BOOLEAN, INT, BOOLEAN
) TO authenticated;
