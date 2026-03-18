-- Migration 002: Create flags table
-- Feature: F-004 (Flags — Save to Supabase)
-- Run: 2026-03-17 in Supabase SQL editor
-- Status: APPLIED

CREATE TABLE IF NOT EXISTS flags (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES profiles(id),
  stop_place_id text,
  stop_name   text,
  flag_type   text,
  flag_icon   text,
  note        text,
  created_at  timestamptz DEFAULT now(),
  expires_at  timestamptz DEFAULT now() + interval '3 hours'
);

ALTER TABLE flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Flags viewable by all"
  ON flags FOR SELECT
  USING (true);

CREATE POLICY "Users insert own flags"
  ON flags FOR INSERT
  WITH CHECK (auth.uid() = user_id);
