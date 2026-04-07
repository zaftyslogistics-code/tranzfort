-- Phase 4 performance indexes for frequently filtered/sorted queries
-- Safe to run repeatedly due to IF NOT EXISTS clauses.

create index if not exists idx_loads_status_parent_created_at
  on public.loads (status, parent_load_id, created_at desc);

create index if not exists idx_loads_supplier_status_created_at
  on public.loads (supplier_id, status, created_at desc);

create index if not exists idx_loads_assigned_trucker_status_created_at
  on public.loads (assigned_trucker_id, status, created_at desc);

create index if not exists idx_notifications_user_read_created_at
  on public.notifications (user_id, is_read, created_at desc);

create index if not exists idx_trips_trucker_stage_created_at
  on public.trips (trucker_id, stage, created_at desc);

create index if not exists idx_user_saved_searches_user_updated_at
  on public.user_saved_searches (user_id, updated_at desc);
