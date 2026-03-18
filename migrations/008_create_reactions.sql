-- Migration 008: Reactions table
-- Feature: Real helpful reactions on check-ins and flags
-- Run: in Supabase SQL editor
-- Status: PENDING

CREATE TABLE IF NOT EXISTS reactions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES profiles(id),
  target_type text NOT NULL CHECK (target_type IN ('checkin', 'flag')),
  target_id   uuid NOT NULL,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(user_id, target_type, target_id)
);

ALTER TABLE reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reactions are public"
  ON reactions FOR SELECT USING (true);

CREATE POLICY "Users can react"
  ON reactions FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unreact"
  ON reactions FOR DELETE USING (auth.uid() = user_id);

-- Index for bulk count queries by target
CREATE INDEX IF NOT EXISTS reactions_target_idx
  ON reactions (target_type, target_id);

-- Index for checking if a user has reacted
CREATE INDEX IF NOT EXISTS reactions_user_idx
  ON reactions (user_id, target_type, target_id);
