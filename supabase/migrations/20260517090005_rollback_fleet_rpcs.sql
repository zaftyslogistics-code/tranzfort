-- Migration: Rollback P3.5 Fleet RPCs
-- Purpose: Drop all fleet RPCs created in P3.5 (rollback)
-- Created: May 17, 2026
-- Part of: P3.5 - Fleet RPCs (Rollback)

-- ═══════════════════════════════════════════════════════════════════════════════
-- Rollback: Drop fleet RPCs
-- ═══════════════════════════════════════════════════════════════════════════════
DROP FUNCTION IF EXISTS get_trucker_fleet(UUID, INT, INT);
DROP FUNCTION IF EXISTS add_truck(TEXT, TEXT, INTEGER, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS update_truck(UUID, TEXT, TEXT, INTEGER, NUMERIC, TEXT);
DROP FUNCTION IF EXISTS archive_truck(UUID);
