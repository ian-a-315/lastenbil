-- Migration 007: Push notification support
-- Feature: F-007 (Push Notifications)
-- Run: in Supabase SQL editor
-- Status: PENDING

-- Add coordinates to flags (for proximity check at dispatch time)
ALTER TABLE flags
  ADD COLUMN IF NOT EXISTS stop_lat double precision,
  ADD COLUMN IF NOT EXISTS stop_lng double precision;

-- Add coordinates to checkins (powers Nearby feed, Convoy, Route Ribbon)
ALTER TABLE checkins
  ADD COLUMN IF NOT EXISTS stop_lat double precision,
  ADD COLUMN IF NOT EXISTS stop_lng double precision;

-- Push subscriptions table
CREATE TABLE IF NOT EXISTS push_subscriptions (
  id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id              uuid REFERENCES profiles(id) UNIQUE,
  subscription         jsonb NOT NULL,
  last_lat             double precision,
  last_lng             double precision,
  permission_granted_at timestamptz DEFAULT now(),
  updated_at           timestamptz DEFAULT now()
);

ALTER TABLE push_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own subscription"
  ON push_subscriptions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Index for geo proximity queries
CREATE INDEX IF NOT EXISTS push_subs_location_idx
  ON push_subscriptions (last_lat, last_lng)
  WHERE last_lat IS NOT NULL;
