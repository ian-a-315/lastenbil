-- Migration 013: Add avatar_url to profiles
-- Feature: User profile photo upload
-- Run: in Supabase SQL editor
-- Status: PENDING

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS avatar_url text;
