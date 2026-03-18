-- Migration 003: Add foreign key from checkins.user_id to profiles.id
-- Required for Supabase PostgREST join syntax: profiles(handle, rig_icon)
-- Without this FK, feed cards and stop profile reviews silently show
-- "driver / 🚛" instead of real handles.
-- Run: in Supabase SQL editor
-- Status: PENDING

ALTER TABLE checkins
  ADD CONSTRAINT checkins_user_id_fkey
  FOREIGN KEY (user_id) REFERENCES profiles(id);
