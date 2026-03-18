-- Migration 009: Add stop_state to checkins
-- Feature: States visited counter on driver profile
-- Run: in Supabase SQL editor
-- Status: PENDING

ALTER TABLE checkins
  ADD COLUMN IF NOT EXISTS stop_state text;

-- Index for counting distinct states per user
CREATE INDEX IF NOT EXISTS checkins_user_state_idx
  ON checkins (user_id, stop_state)
  WHERE stop_state IS NOT NULL;
