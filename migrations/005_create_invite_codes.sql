-- Migration 005: Invite codes + redeem function
-- Feature: F-010 (Invite System)
-- Run: in Supabase SQL editor
-- Status: PENDING

CREATE TABLE IF NOT EXISTS invite_codes (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code          text UNIQUE NOT NULL,
  batch_name    text,
  max_uses      int  NOT NULL DEFAULT 1600,
  current_uses  int  NOT NULL DEFAULT 0,
  expires_at    timestamptz,
  founding_driver bool NOT NULL DEFAULT true,
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE invite_codes ENABLE ROW LEVEL SECURITY;

-- Anyone can read (needed for client-side validation UX)
CREATE POLICY "Invite codes readable by all"
  ON invite_codes FOR SELECT
  USING (true);

-- No user inserts/updates — managed by admin via service role

-- ── Redeem function (runs as SECURITY DEFINER to bypass RLS on UPDATE) ──
CREATE OR REPLACE FUNCTION redeem_invite_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_row invite_codes%ROWTYPE;
BEGIN
  SELECT * INTO v_row
  FROM invite_codes
  WHERE code = upper(p_code)
    AND (expires_at IS NULL OR expires_at > now())
    AND current_uses < max_uses;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', false, 'error', 'Invalid or expired code');
  END IF;

  UPDATE invite_codes
    SET current_uses = current_uses + 1
    WHERE id = v_row.id;

  RETURN jsonb_build_object(
    'valid',           true,
    'founding_driver', v_row.founding_driver,
    'batch_name',      v_row.batch_name
  );
END;
$$;

-- ── Seed the first batch code ──────────────────────────────────────────
-- After running this migration, insert your first code:
--
-- INSERT INTO invite_codes (code, batch_name, max_uses, founding_driver)
-- VALUES ('KEEPMOVING2026', 'March 2026 CW Policyholder Blast', 1600, true);
--
-- Share this URL in the email blast:
-- https://lastenbil.vercel.app/?invite=KEEPMOVING2026
