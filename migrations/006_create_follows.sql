-- Migration 006: Create follows table
-- Feature: F-008 (Following System)
-- Run: in Supabase SQL editor
-- Status: PENDING

CREATE TABLE IF NOT EXISTS follows (
  follower_id  uuid REFERENCES profiles(id),
  following_id uuid REFERENCES profiles(id),
  created_at   timestamptz DEFAULT now(),
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

-- Users can see who they follow (needed for feed filtering)
CREATE POLICY "Users can view own follows"
  ON follows FOR SELECT
  USING (auth.uid() = follower_id);

-- Users can follow others
CREATE POLICY "Users can follow"
  ON follows FOR INSERT
  WITH CHECK (auth.uid() = follower_id);

-- Users can unfollow
CREATE POLICY "Users can unfollow"
  ON follows FOR DELETE
  USING (auth.uid() = follower_id);
