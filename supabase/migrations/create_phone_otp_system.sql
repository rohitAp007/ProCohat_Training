-- ============================================================================
-- CUSTOM OTP SYSTEM - DATABASE SCHEMA
-- ============================================================================
-- Creates tables and functions for manual OTP authentication without Twilio
-- ============================================================================

-- Create phone_otps table
CREATE TABLE IF NOT EXISTS public.phone_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_number TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  attempts INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT phone_otps_phone_check CHECK (LENGTH(phone_number) >= 10 AND LENGTH(phone_number) <= 15),
  CONSTRAINT phone_otps_otp_check CHECK (LENGTH(otp_code) = 6 AND otp_code ~ '^[0-9]+$')
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_phone_otps_phone ON phone_otps(phone_number);
CREATE INDEX IF NOT EXISTS idx_phone_otps_expires ON phone_otps(expires_at);
CREATE INDEX IF NOT EXISTS idx_phone_otps_verified ON phone_otps(verified);
CREATE INDEX IF NOT EXISTS idx_phone_otps_created ON phone_otps(created_at);

-- Enable Row Level Security
ALTER TABLE phone_otps ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Service role full access (for Edge Functions)
CREATE POLICY "Service role full access on phone_otps"
  ON phone_otps
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- RLS Policy: No direct user access
CREATE POLICY "No direct user access to phone_otps"
  ON phone_otps
  FOR ALL
  TO authenticated, anon
  USING (false)
  WITH CHECK (false);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to cleanup old OTPs (older than 1 hour)
CREATE OR REPLACE FUNCTION cleanup_old_otps()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM phone_otps 
  WHERE created_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- Function to get active OTP count for rate limiting
CREATE OR REPLACE FUNCTION get_recent_otp_count(p_phone TEXT)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  otp_count INT;
BEGIN
  SELECT COUNT(*)
  INTO otp_count
  FROM phone_otps
  WHERE phone_number = p_phone
    AND created_at > NOW() - INTERVAL '15 minutes';
    
  RETURN otp_count;
END;
$$;

-- Function to invalidate all previous OTPs for a phone
CREATE OR REPLACE FUNCTION invalidate_previous_otps(p_phone TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE phone_otps
  SET verified = true,
      updated_at = NOW()
  WHERE phone_number = p_phone
    AND verified = false;
END;
$$;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER update_phone_otps_updated_at
  BEFORE UPDATE ON phone_otps
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SCHEDULED CLEANUP (Optional - requires pg_cron extension)
-- ============================================================================

-- Uncomment if you have pg_cron enabled:
-- SELECT cron.schedule(
--   'cleanup-old-otps',
--   '0 * * * *', -- Run every hour
--   $$SELECT cleanup_old_otps()$$
-- );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permissions on functions to service role
GRANT EXECUTE ON FUNCTION cleanup_old_otps() TO service_role;
GRANT EXECUTE ON FUNCTION get_recent_otp_count(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION invalidate_previous_otps(TEXT) TO service_role;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE phone_otps IS 'Stores OTP codes for phone authentication';
COMMENT ON COLUMN phone_otps.phone_number IS 'Full phone number with country code (e.g., +917666086414)';
COMMENT ON COLUMN phone_otps.otp_code IS '6-digit numeric OTP code';
COMMENT ON COLUMN phone_otps.expires_at IS 'Expiration timestamp (typically 5 minutes from creation)';
COMMENT ON COLUMN phone_otps.verified IS 'Whether OTP has been successfully verified';
COMMENT ON COLUMN phone_otps.attempts IS 'Number of failed verification attempts';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify table was created
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'phone_otps') THEN
    RAISE EXCEPTION 'phone_otps table was not created successfully';
  END IF;
  
  RAISE NOTICE '✅ phone_otps table created successfully';
  RAISE NOTICE '✅ RLS policies applied';
  RAISE NOTICE '✅ Helper functions created';
  RAISE NOTICE '✅ Triggers configured';
END $$;
