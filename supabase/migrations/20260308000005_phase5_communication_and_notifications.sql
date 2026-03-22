-- ============================================================================
-- TranZfort Rebuild — Phase 5: Communication & Notifications
-- Source of truth: docs/26-schema-tables-communication.md
-- docs/27-schema-tables-notifications.md
-- ============================================================================

-- ─── conversations ───
-- Canonical chat thread anchor between supplier and trucker
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL REFERENCES suppliers(id) ON DELETE CASCADE,
  trucker_id UUID NOT NULL REFERENCES truckers(id) ON DELETE CASCADE,
  load_id UUID REFERENCES loads(id),
  trip_id UUID REFERENCES trips(id),
  last_message_at TIMESTAMPTZ,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Uniqueness: one conversation per supplier+trucker+load context
  UNIQUE(supplier_id, trucker_id, load_id)
);

CREATE INDEX idx_conversations_supplier_last ON conversations(supplier_id, last_message_at DESC);
CREATE INDEX idx_conversations_trucker_last ON conversations(trucker_id, last_message_at DESC);
CREATE INDEX idx_conversations_load ON conversations(load_id);

-- ─── messages ───
-- Canonical message record within a conversation
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_profile_id UUID REFERENCES profiles(id),
  message_type message_type NOT NULL DEFAULT 'text',
  text_body TEXT,
  attachment_path TEXT,
  structured_payload JSONB,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_sender ON messages(sender_profile_id);

-- ─── notifications ───
-- Durable notification record for user and admin actors
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  target_profile_id UUID REFERENCES profiles(id),
  target_admin_user_id UUID REFERENCES admin_users(id),
  notification_type notification_type NOT NULL,
  notification_priority notification_priority NOT NULL DEFAULT 'medium',
  title_text TEXT,
  body_text TEXT,
  related_load_id UUID REFERENCES loads(id),
  related_trip_id UUID REFERENCES trips(id),
  related_case_id UUID,
  action_route_hint TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_profile_created ON notifications(target_profile_id, created_at DESC);
CREATE INDEX idx_notifications_admin_created ON notifications(target_admin_user_id, created_at DESC);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_profile_unread ON notifications(target_profile_id, is_read, created_at DESC);
