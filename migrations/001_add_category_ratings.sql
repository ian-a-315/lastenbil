-- Migration 001: Add category rating columns to checkins
-- Feature: F-003 (Save Category Ratings)
-- Run: 2026-03-17 in Supabase SQL editor
-- Status: APPLIED

ALTER TABLE checkins
  ADD COLUMN IF NOT EXISTS rating_parking int,
  ADD COLUMN IF NOT EXISTS rating_showers int,
  ADD COLUMN IF NOT EXISTS rating_food int,
  ADD COLUMN IF NOT EXISTS rating_safety int,
  ADD COLUMN IF NOT EXISTS rating_fuel int,
  ADD COLUMN IF NOT EXISTS note text;
