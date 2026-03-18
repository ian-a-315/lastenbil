-- Migration 010: Reports table
-- Feature: Content moderation (manual review)
-- Run: in Supabase SQL editor
-- Status: PENDING

CREATE TABLE IF NOT EXISTS reports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES profiles(id),
  target_type text NOT NULL CHECK (target_type IN ('checkin', 'flag')),
  target_id   uuid NOT NULL,
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- Reporters can insert (anyone signed in can report)
CREATE POLICY "Users can report"
  ON reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Only service role can read (admin manual review via Supabase dashboard)
