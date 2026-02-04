-- Migration: Asset Payouts Tracking & FCM Support
-- Created: 2026-02-04
-- Purpose: Track actual payments received from manual assets and enable FCM notifications

-- ============================================================================
-- 1. ADD FCM TOKEN SUPPORT TO PROFILES TABLE
-- ============================================================================

-- Add fcm_token column to profiles table if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Add index for faster FCM token lookups
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token 
ON profiles(fcm_token) 
WHERE fcm_token IS NOT NULL;

COMMENT ON COLUMN profiles.fcm_token IS 'Firebase Cloud Messaging token for push notifications';

-- ============================================================================
-- 2. CREATE ASSET_PAYOUTS TABLE
-- ============================================================================

-- Table to store history of actual payments received from manual assets
CREATE TABLE IF NOT EXISTS asset_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
  amount NUMERIC(20, 2) NOT NULL CHECK (amount > 0),
  payout_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_asset_payouts_user_id ON asset_payouts(user_id);
CREATE INDEX IF NOT EXISTS idx_asset_payouts_asset_id ON asset_payouts(asset_id);
CREATE INDEX IF NOT EXISTS idx_asset_payouts_payout_date ON asset_payouts(payout_date DESC);
CREATE INDEX IF NOT EXISTS idx_asset_payouts_user_asset ON asset_payouts(user_id, asset_id);

-- Add RLS (Row Level Security) policies
ALTER TABLE asset_payouts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own payouts
CREATE POLICY "Users can view own payouts" 
ON asset_payouts FOR SELECT 
USING (auth.uid() = user_id);

-- Policy: Users can insert their own payouts
CREATE POLICY "Users can insert own payouts" 
ON asset_payouts FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own payouts
CREATE POLICY "Users can update own payouts" 
ON asset_payouts FOR UPDATE 
USING (auth.uid() = user_id);

-- Policy: Users can delete their own payouts
CREATE POLICY "Users can delete own payouts" 
ON asset_payouts FOR DELETE 
USING (auth.uid() = user_id);

-- Add comments for documentation
COMMENT ON TABLE asset_payouts IS 'Tracks actual payments received from manual assets (amortization history)';
COMMENT ON COLUMN asset_payouts.id IS 'Unique identifier for the payout record';
COMMENT ON COLUMN asset_payouts.user_id IS 'Owner of the asset';
COMMENT ON COLUMN asset_payouts.asset_id IS 'Reference to the manual asset';
COMMENT ON COLUMN asset_payouts.amount IS 'Amount received in the payout';
COMMENT ON COLUMN asset_payouts.payout_date IS 'Date when the payment was received';
COMMENT ON COLUMN asset_payouts.notes IS 'Optional notes about the payout';

-- ============================================================================
-- 3. UPDATE ASSET_REMINDERS TABLE (ENSURE PROPER LINKS)
-- ============================================================================

-- Ensure asset_reminders has proper foreign key to assets
-- (This should already exist, but we verify it here)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'asset_reminders_asset_id_fkey'
  ) THEN
    ALTER TABLE asset_reminders 
    ADD CONSTRAINT asset_reminders_asset_id_fkey 
    FOREIGN KEY (asset_id) REFERENCES assets(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Add index on next_event_date for cron job performance
CREATE INDEX IF NOT EXISTS idx_asset_reminders_next_event_date 
ON asset_reminders(next_event_date);

-- Add index for user_id + next_event_date for FCM queries
CREATE INDEX IF NOT EXISTS idx_asset_reminders_user_next_event 
ON asset_reminders(user_id, next_event_date);

-- ============================================================================
-- 4. CREATE HELPER FUNCTION: GET ASSET PAYOUT SUMMARY
-- ============================================================================

-- Function to calculate payout summary for a specific asset
CREATE OR REPLACE FUNCTION get_asset_payout_summary(p_asset_id UUID)
RETURNS TABLE (
  total_expected NUMERIC,
  total_received NUMERIC,
  remaining_balance NUMERIC,
  payout_count INTEGER,
  last_payout_date TIMESTAMP WITH TIME ZONE
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(a.balance_usd, 0) AS total_expected,
    COALESCE(SUM(ap.amount), 0) AS total_received,
    COALESCE(a.balance_usd, 0) - COALESCE(SUM(ap.amount), 0) AS remaining_balance,
    COUNT(ap.id)::INTEGER AS payout_count,
    MAX(ap.payout_date) AS last_payout_date
  FROM assets a
  LEFT JOIN asset_payouts ap ON ap.asset_id = a.id
  WHERE a.id = p_asset_id
  GROUP BY a.id, a.balance_usd;
END;
$$;

COMMENT ON FUNCTION get_asset_payout_summary IS 'Calculate total expected, received, and remaining balance for a manual asset';

-- ============================================================================
-- 5. CREATE HELPER FUNCTION: UPDATE NEXT EVENT DATE AFTER PAYOUT
-- ============================================================================

-- Function to automatically update next_event_date in asset_reminders
-- when a payout is marked as received
CREATE OR REPLACE FUNCTION update_reminder_next_event_date(
  p_reminder_id UUID,
  p_rrule_expression TEXT
)
RETURNS TIMESTAMP WITH TIME ZONE
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_next_date TIMESTAMP WITH TIME ZONE;
BEGIN
  -- Calculate next occurrence based on RRULE
  -- This is a simplified version - in production, use a proper RRULE parser
  
  -- For now, we'll add interval based on frequency
  SELECT 
    CASE 
      WHEN p_rrule_expression LIKE '%FREQ=DAILY%' THEN 
        next_event_date + INTERVAL '1 day'
      WHEN p_rrule_expression LIKE '%FREQ=WEEKLY%' THEN 
        next_event_date + INTERVAL '1 week'
      WHEN p_rrule_expression LIKE '%FREQ=MONTHLY%' THEN 
        next_event_date + INTERVAL '1 month'
      WHEN p_rrule_expression LIKE '%FREQ=YEARLY%' THEN 
        next_event_date + INTERVAL '1 year'
      ELSE 
        next_event_date + INTERVAL '1 month' -- Default to monthly
    END INTO v_next_date
  FROM asset_reminders
  WHERE id = p_reminder_id;
  
  -- Update the reminder with new next_event_date
  UPDATE asset_reminders
  SET next_event_date = v_next_date,
      updated_at = NOW()
  WHERE id = p_reminder_id;
  
  RETURN v_next_date;
END;
$$;

COMMENT ON FUNCTION update_reminder_next_event_date IS 'Calculate and update next event date based on RRULE expression';

-- ============================================================================
-- 6. CREATE TRIGGER: AUTO-UPDATE TIMESTAMPS
-- ============================================================================

-- Trigger function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to asset_payouts
DROP TRIGGER IF EXISTS update_asset_payouts_updated_at ON asset_payouts;
CREATE TRIGGER update_asset_payouts_updated_at
  BEFORE UPDATE ON asset_payouts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 7. SETUP CRON JOB FOR DAILY REMINDERS (pg_cron)
-- ============================================================================

-- Note: pg_cron must be enabled in Supabase project settings first
-- This requires superuser access, so it should be run manually via Supabase Dashboard

-- Enable pg_cron extension (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily reminder check at 08:00 AM UTC
-- This will invoke the send-asset-reminders Edge Function
SELECT cron.schedule(
  'send-daily-asset-reminders',  -- Job name
  '0 8 * * *',                    -- Cron expression: Every day at 08:00 AM UTC
  $$
  SELECT
    net.http_post(
      url := 'https://nbdfdlvbouoaoprbkbme.supabase.co/functions/v1/send-asset-reminders',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
      ),
      body := jsonb_build_object('trigger', 'cron')
    ) AS request_id;
  $$
);

-- ============================================================================
-- 8. GRANT PERMISSIONS
-- ============================================================================

-- Grant necessary permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON asset_payouts TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================

-- Verify tables exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'asset_payouts') THEN
    RAISE NOTICE 'Migration successful: asset_payouts table created';
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'fcm_token') THEN
    RAISE NOTICE 'Migration successful: fcm_token column added to profiles';
  END IF;
END $$;
