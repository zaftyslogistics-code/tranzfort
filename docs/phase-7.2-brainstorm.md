# Phase 7.2 Brainstorm: Support Attachment Lifecycle Redesign

## Current State Analysis

### Backend Infrastructure (Already Exists)

**Table: `ticket_attachments`**
```sql
CREATE TABLE public.ticket_attachments (
  id UUID PRIMARY KEY,
  ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
  uploaded_by UUID NOT NULL REFERENCES profiles(id),
  
  -- File metadata
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL, -- Storage path
  file_size BIGINT NOT NULL,
  mime_type TEXT NOT NULL,
  file_hash TEXT, -- SHA-256 for deduplication
  
  -- Upload status
  upload_status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'uploading', 'uploaded', 'failed'
  upload_error_message TEXT,
  retry_count INT DEFAULT 0,
  max_retries INT DEFAULT 3,
  
  -- Scan status
  scan_status TEXT DEFAULT 'pending', -- 'pending', 'scanning', 'clean', 'infected', 'failed'
  scan_result TEXT,
  scanned_at TIMESTAMPTZ,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Existing RPCs:**
1. `create_support_ticket(p_category, p_message_body, p_related_load_id, p_related_trip_id, p_attachment_path, p_priority)`
   - Accepts SINGLE attachment path
   - Creates ticket + initial message with attachment
   
2. `reply_to_support_ticket(p_support_ticket_id, p_message_body, p_visibility_class, p_attachment_path)`
   - Accepts SINGLE attachment path
   - Adds reply with attachment
   
3. `get_ticket_attachments(p_ticket_id)`
   - Returns JSONB array of all attachments for a ticket

### Flutter App Current Flow

**SupportAttachmentUploadService:**
```dart
uploadMultipleAttachments({
  required String ticketId,  // ← REQUIRES ticket_id upfront
  required String profileId,
  required List<ImageSource> sources,
  String pathSegment = 'support_ticket',
})
```

**Current Storage Path:**
```
{profileId}/support_ticket/{ticketId}/attachment_{timestamp}.jpg
```

**Current TODO in code:**
```dart
// create_support_ticket_screen.dart:215
// TODO: Implement multiple attachment upload after ticket creation
// For now, attachments can be added after ticket is created via reply
```

### The Problem

1. **User wants to attach files BEFORE creating ticket**
   - User fills out form → picks attachments → submits
   - Current flow: User must create ticket first → then add attachments via reply
   
2. **Cancellation creates orphaned files**
   - If user cancels after uploading but before creating ticket
   - Files exist in storage but no ticket references them
   - No cleanup mechanism

3. **Multiple attachments not supported in initial message**
   - RPC only accepts single `p_attachment_path`
   - Backend has `ticket_attachments` table but RPC doesn't use it
   - Flutter service uploads to table but RPC doesn't know about it

---

## Proposed Solutions

### Option A: Draft Session ID Approach (Original Plan)

**Concept:**
- Generate UUID session ID on screen init
- Upload files under draft namespace: `{profileId}/draft/{session_id}/`
- Create attachment records with `ticket_id = NULL` + `session_id`
- When ticket submitted, call RPC to finalize attachments
- Cleanup job deletes orphaned draft attachments

**Backend Changes Required:**

1. **Schema Change:**
```sql
ALTER TABLE ticket_attachments ADD COLUMN session_id UUID;
ALTER TABLE ticket_attachments ALTER COLUMN ticket_id DROP NOT NULL;
CREATE INDEX idx_ticket_attachments_session_id ON ticket_attachments(session_id);
```

2. **New RPC: `create_support_ticket_from_draft`**
```sql
CREATE OR REPLACE FUNCTION create_support_ticket_from_draft(
  p_session_id UUID,
  p_category TEXT,
  p_message_body TEXT,
  p_related_load_id UUID DEFAULT NULL,
  p_related_trip_id UUID DEFAULT NULL,
  p_priority support_ticket_priority DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_ticket_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  -- Create ticket
  INSERT INTO support_tickets (...)
  VALUES (...) RETURNING id INTO v_ticket_id;
  
  -- Finalize all draft attachments
  UPDATE ticket_attachments
  SET ticket_id = v_ticket_id,
      upload_status = 'uploaded',
      updated_at = NOW()
  WHERE session_id = p_session_id
    AND uploaded_by = v_user_id
    AND ticket_id IS NULL;
  
  RETURN v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

3. **New RPC: `cleanup_stale_draft_attachments`**
```sql
CREATE OR REPLACE FUNCTION cleanup_stale_draft_attachments()
RETURNS INT AS $$
BEGIN
  DELETE FROM ticket_attachments
  WHERE ticket_id IS NULL
    AND created_at < NOW() - INTERVAL '24 hours';
  
  -- Also delete files from storage (would need storage cleanup function)
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;
```

**Flutter Changes Required:**

1. **Generate session ID:**
```dart
class CreateSupportTicketState {
  final String sessionId = const Uuid().v4();
  final List<TicketAttachmentMetadata> attachments = [];
}
```

2. **Upload to draft namespace:**
```dart
uploadMultipleAttachments({
  required String sessionId,  // ← Use session_id instead of ticket_id
  required String profileId,
  String pathSegment = 'draft',  // ← Changed from 'support_ticket'
})
```

3. **Create ticket via new RPC:**
```dart
final ticketId = await _client.rpc(
  'create_support_ticket_from_draft',
  params: {
    'p_session_id': sessionId,
    'p_category': category,
    'p_message_body': messageBody,
    ...
  },
);
```

4. **Cancel cleanup:**
```dart
Future<void> _cancelDraftSession(String sessionId) async {
  await _deleteAttachmentsBySessionId(sessionId);
}
```

**Pros:**
- ✅ Clean separation of draft vs finalized attachments
- ✅ Can have multiple concurrent drafts (different session IDs)
- ✅ Easy to identify orphaned drafts for cleanup
- ✅ Supports multiple attachments in initial message

**Cons:**
- ❌ Requires schema change (add session_id column)
- ❌ Requires new backend RPCs (2 new functions)
- ❌ Requires storage cleanup for orphaned files
- ❌ More complex migration path

---

### Option B: Ticket-Nullable Approach (Simpler)

**Concept:**
- Keep existing table structure
- Allow `ticket_id` to be NULL temporarily
- Upload files with `ticket_id = NULL` + `uploaded_by = user_id`
- When ticket created, update all NULL attachments for that user
- Cleanup job deletes orphaned NULL attachments

**Backend Changes Required:**

1. **Schema Change:**
```sql
ALTER TABLE ticket_attachments ALTER COLUMN ticket_id DROP NOT NULL;
```

2. **New RPC: `create_support_ticket_with_attachments`**
```sql
CREATE OR REPLACE FUNCTION create_support_ticket_with_attachments(
  p_category TEXT,
  p_message_body TEXT,
  p_related_load_id UUID DEFAULT NULL,
  p_related_trip_id UUID DEFAULT NULL,
  p_priority support_ticket_priority DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_ticket_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();
  
  -- Create ticket
  INSERT INTO support_tickets (...)
  VALUES (...) RETURNING id INTO v_ticket_id;
  
  -- Finalize all user's pending attachments
  UPDATE ticket_attachments
  SET ticket_id = v_ticket_id,
      upload_status = 'uploaded',
      updated_at = NOW()
  WHERE uploaded_by = v_user_id
    AND ticket_id IS NULL;
  
  RETURN v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

3. **Cleanup RPC (same as Option A):**
```sql
CREATE OR REPLACE FUNCTION cleanup_orphaned_attachments()
RETURNS INT AS $$
BEGIN
  DELETE FROM ticket_attachments
  WHERE ticket_id IS NULL
    AND created_at < NOW() - INTERVAL '24 hours';
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql;
```

**Flutter Changes Required:**

1. **Upload without ticket_id:**
```dart
uploadMultipleAttachments({
  required String profileId,
  String pathSegment = 'pending',  // ← Use 'pending' namespace
  String? ticketId,  // ← Make optional
})
```

2. **Create ticket via new RPC:**
```dart
final ticketId = await _client.rpc(
  'create_support_ticket_with_attachments',
  params: {
    'p_category': category,
    'p_message_body': messageBody,
    ...
  },
);
```

**Pros:**
- ✅ Minimal schema change (just DROP NOT NULL)
- ✅ Only 1 new backend RPC (plus cleanup)
- ✅ Simpler to implement
- ✅ Supports multiple attachments in initial message

**Cons:**
- ❌ Can't have multiple concurrent drafts (all NULL attachments for user)
- ❌ If user starts multiple forms, attachments get mixed
- ❌ Still requires storage cleanup for orphaned files

---

### Option C: Client-Side Batch Upload (No Backend Changes)

**Concept:**
- Keep files in memory/local cache until ticket submitted
- Upload all files in batch AFTER ticket creation
- Use existing RPCs with single attachment (iterate)
- Or modify RPC to accept multiple attachment paths

**Backend Changes Required:**

1. **Option C1: Modify existing RPC to accept multiple attachments**
```sql
CREATE OR REPLACE FUNCTION create_support_ticket(
  p_category TEXT,
  p_message_body TEXT,
  p_related_load_id UUID DEFAULT NULL,
  p_related_trip_id UUID DEFAULT NULL,
  p_attachment_paths TEXT[] DEFAULT NULL,  -- ← Change to array
  p_priority support_ticket_priority DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_ticket_id UUID;
  v_attachment_path TEXT;
BEGIN
  -- Create ticket (same as before)
  INSERT INTO support_tickets (...) VALUES (...) RETURNING id INTO v_ticket_id;
  
  -- Create initial message (same as before)
  INSERT INTO support_ticket_messages (...) VALUES (...);
  
  -- Create attachment records for each path
  FOREACH v_attachment_path IN ARRAY p_attachment_paths
  LOOP
    INSERT INTO ticket_attachments (
      ticket_id, uploaded_by, file_name, file_path, 
      file_size, mime_type, upload_status, scan_status
    ) VALUES (
      v_ticket_id, auth.uid(), 
      SPLIT_PART(v_attachment_path, '/', -1),
      v_attachment_path,
      0, 'image/jpeg', 'uploaded', 'pending'
    );
  END LOOP;
  
  RETURN v_ticket_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Flutter Changes Required:**

1. **Cache files locally:**
```dart
class CreateSupportTicketState {
  final List<XFile> pendingAttachments = [];
}

Future<void> _pickAttachment(ImageSource source) async {
  final file = await ImagePicker().pickImage(source: source);
  if (file != null) {
    state.pendingAttachments.add(file);
  }
}
```

2. **Upload batch after ticket creation:**
```dart
Future<void> _submitTicket() async {
  // 1. Create ticket first
  final ticketId = await createTicket(...);
  
  // 2. Upload all attachments in batch
  final attachmentPaths = await Future.wait(
    state.pendingAttachments.map((file) => _uploadAttachment(file, ticketId))
  );
  
  // 3. Update ticket with attachments (if using array parameter)
  // OR create attachment records directly
}
```

**Pros:**
- ✅ No schema changes
- ✅ Minimal backend changes (just modify RPC signature)
- ✅ No orphaned files (only upload after ticket created)
- ✅ Simple cancellation (just clear local cache)

**Cons:**
- ❌ Large files cause memory issues (holding all files in memory)
- ❌ No retry if individual upload fails (or complex retry logic)
- ❌ User loses files if app crashes before submission
- ❌ Poor UX for slow networks (wait for all uploads before ticket created)

---

### Option D: Hybrid Approach (Recommended)

**Concept:**
- Upload files immediately to storage (like current flow)
- Use temporary storage path: `{profileId}/temp/{session_id}/`
- Create attachment records with `ticket_id = NULL` + `session_id`
- When ticket created, finalize attachments (update ticket_id + move files)
- Cleanup job handles orphaned files
- **Key difference from Option A:** Use storage path instead of database column for session tracking

**Backend Changes Required:**

1. **Schema Change (Minimal):**
```sql
ALTER TABLE ticket_attachments ALTER COLUMN ticket_id DROP NOT NULL;
-- Add index for cleanup
CREATE INDEX idx_ticket_attachments_orphaned ON ticket_attachments(ticket_id) 
  WHERE ticket_id IS NULL;
```

2. **New RPC: `finalize_ticket_attachments`**
```sql
CREATE OR REPLACE FUNCTION finalize_ticket_attachments(
  p_ticket_id UUID,
  p_session_id TEXT
)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE ticket_attachments
  SET ticket_id = p_ticket_id,
      upload_status = 'uploaded',
      updated_at = NOW()
  WHERE uploaded_by = auth.uid()
    AND ticket_id IS NULL
    AND file_path LIKE '%' || p_session_id || '%';
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

3. **Storage Move Function (Supabase Storage doesn't have built-in move):**
```sql
-- This would be called from Flutter or via edge function
-- Supabase Storage doesn't support server-side move, so we do it client-side
```

**Flutter Changes Required:**

1. **Upload to temp namespace:**
```dart
uploadMultipleAttachments({
  required String sessionId,
  required String profileId,
  String pathSegment = 'temp',  // ← Use 'temp' namespace
})
// Storage path: {profileId}/temp/{sessionId}/attachment_{timestamp}.jpg
```

2. **Create ticket with existing RPC:**
```dart
final ticketId = await createTicket(...);
```

3. **Finalize attachments:**
```dart
await _client.rpc(
  'finalize_ticket_attachments',
  params: {
    'p_ticket_id': ticketId,
    'p_session_id': sessionId,
  },
);
```

4. **Cancel cleanup:**
```dart
Future<void> _cancelDraftSession(String sessionId) async {
  // Delete attachment records
  await _deleteAttachmentsBySessionId(sessionId);
  
  // Delete files from storage
  await _deleteStorageFilesBySessionId(sessionId);
}
```

**Pros:**
- ✅ Minimal schema change (just DROP NOT NULL)
- ✅ Only 1 new backend RPC
- ✅ Files uploaded immediately (good UX)
- ✅ Session tracking via storage path (no new column needed)
- ✅ Supports multiple attachments
- ✅ Easy cleanup

**Cons:**
- ❌ Need client-side storage move (or accept temp path)
- ❌ Still requires cleanup job for orphaned files
- ❌ Session ID in file path is a bit hacky

---

## Recommendation

**Go with Option D (Hybrid Approach)**

**Rationale:**
1. **Lowest risk:** Minimal schema change (just DROP NOT NULL)
2. **Fewest backend changes:** Only 1 new RPC
3. **Best UX:** Files upload immediately, no waiting
4. **Cleanest cleanup:** Session tracking via storage path
5. **Supports multiple attachments:** Solves the original problem

**Implementation Steps:**

### Phase 7.2.1: Backend Changes (Backend Team)

1. **Migration:**
```sql
-- 20260512000001_allow_null_ticket_id_in_attachments.sql
ALTER TABLE public.ticket_attachments ALTER COLUMN ticket_id DROP NOT NULL;
CREATE INDEX idx_ticket_attachments_orphaned ON public.ticket_attachments(ticket_id) 
  WHERE ticket_id IS NULL;
```

2. **RPC:**
```sql
-- 20260512000002_finalize_ticket_attachments.sql
CREATE OR REPLACE FUNCTION finalize_ticket_attachments(
  p_ticket_id UUID,
  p_session_id TEXT
)
RETURNS INT AS $$
DECLARE
  v_count INT;
BEGIN
  UPDATE ticket_attachments
  SET ticket_id = p_ticket_id,
      upload_status = 'uploaded',
      updated_at = NOW()
  WHERE uploaded_by = auth.uid()
    AND ticket_id IS NULL
    AND file_path LIKE '%' || p_session_id || '%';
  
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION finalize_ticket_attachments(UUID, TEXT) TO authenticated;
```

3. **Cleanup RPC (Optional, can be done later):**
```sql
-- 20260512000003_cleanup_orphaned_attachments.sql
CREATE OR REPLACE FUNCTION cleanup_orphaned_attachments()
RETURNS INT AS $$
BEGIN
  DELETE FROM ticket_attachments
  WHERE ticket_id IS NULL
    AND created_at < NOW() - INTERVAL '24 hours';
  
  -- Note: Storage cleanup would need to be done separately
  -- via edge function or client-side
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION cleanup_orphaned_attachments() TO authenticated;
```

### Phase 7.2.2: Flutter Changes (Our Team)

1. **Add session ID to state:**
```dart
// support_compose_providers.dart
class CreateSupportTicketState {
  final String sessionId = const Uuid().v4();  // ← Add
  final List<TicketAttachmentMetadata> attachments = [];
  // ... existing fields
}
```

2. **Update upload service:**
```dart
// support_attachment_upload_service.dart
Future<Result<List<TicketAttachmentMetadata>>> uploadMultipleAttachments({
  required String sessionId,  // ← Changed from ticketId
  required String profileId,
  required List<ImageSource> sources,
  String pathSegment = 'temp',  // ← Changed from 'support_ticket'
}) async {
  // Storage path: {profileId}/temp/{sessionId}/attachment_{timestamp}.jpg
  // Create attachment records with ticket_id = NULL
}
```

3. **Update submit flow:**
```dart
// support_compose_providers.dart
Future<Result<String>> submit() async {
  // 1. Create ticket with existing RPC (no attachment path)
  final ticketId = await _backend.createTicket(
    category: state.category,
    messageBody: state.description,
    // No attachmentPath parameter
  );
  
  // 2. Finalize attachments
  await _client.rpc(
    'finalize_ticket_attachments',
    params: {
      'p_ticket_id': ticketId,
      'p_session_id': state.sessionId,
    },
  );
  
  return Success(ticketId);
}
```

4. **Add cancel cleanup:**
```dart
Future<void> _cancelDraftSession(String sessionId) async {
  // Delete attachment records
  await _database.deleteAttachmentsBySessionId(sessionId);
  
  // Delete files from storage
  final files = await _storage.list('support-attachments', path: '$profileId/temp/$sessionId');
  if (files.isNotEmpty) {
    await _storage.remove(files.map((f) => f.name).toList());
  }
}
```

### Phase 7.2.3: Testing

1. **Unit Tests:**
   - Test upload with session ID
   - Test finalize attachments RPC
   - Test cancel cleanup

2. **Integration Tests:**
   - Test full flow: pick attachments → create ticket → finalize
   - Test cancellation: pick attachments → cancel → verify cleanup
   - Test orphaned cleanup (if implemented)

3. **Manual Testing:**
   - Test with multiple attachments
   - Test with large files
   - Test with slow network
   - Test app crash during attachment upload

---

## Alternative: Defer Phase 7.2

**Given the complexity, consider deferring Phase 7.2 until:**

1. Backend team has capacity to implement the RPCs
2. Storage cleanup strategy is finalized (edge function vs client-side)
3. Multiple attachments in initial message is a high-priority feature

**Current workaround exists:**
- Users can create ticket first
- Then add attachments via reply
- Not ideal, but functional

**Priority decision:**
- If multiple attachments in initial message is blocking a key user story → implement Option D
- If it's a nice-to-have → defer and work on other phases
