-- Migration: Create finance tables for asset tracking and wealth history
-- Description: Unified schema for crypto (Moralis) and bank (Plaid) asset management
-- Author: Finance Realtime Engine
-- Date: 2026-01-20

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Asset type enumeration
CREATE TYPE asset_type AS ENUM ('crypto', 'bank');

-- Provider enumeration
CREATE TYPE asset_provider AS ENUM ('moralis', 'plaid');

-- ============================================================================
-- TABLES
-- ============================================================================

-- Assets table: Stores all user assets (crypto and bank accounts)
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    type asset_type NOT NULL,
    provider asset_provider NOT NULL,
    balance_usd DECIMAL(20, 2) NOT NULL DEFAULT 0.00,
    asset_address_or_id VARCHAR(500) NOT NULL,
    last_sync TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Unique constraint to prevent duplicate assets
    CONSTRAINT unique_user_asset UNIQUE (user_id, asset_address_or_id)
);

-- Wealth history table: Tracks total wealth over time for charts
CREATE TABLE IF NOT EXISTS wealth_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_amount DECIMAL(20, 2) NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    
    -- Index for efficient time-series queries
    CONSTRAINT idx_user_timestamp UNIQUE (user_id, timestamp)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for fast user asset lookups
CREATE INDEX IF NOT EXISTS idx_assets_user_id ON assets(user_id);

-- Index for provider-based queries
CREATE INDEX IF NOT EXISTS idx_assets_provider ON assets(provider);

-- Index for asset type queries
CREATE INDEX IF NOT EXISTS idx_assets_type ON assets(type);

-- Index for wealth history time-series queries
CREATE INDEX IF NOT EXISTS idx_wealth_history_user_timestamp ON wealth_history(user_id, timestamp DESC);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to update updated_at timestamp on assets table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_assets_updated_at
    BEFORE UPDATE ON assets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on assets table
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own assets
CREATE POLICY assets_select_policy ON assets
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can only insert their own assets
CREATE POLICY assets_insert_policy ON assets
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- Policy: Users can only update their own assets
CREATE POLICY assets_update_policy ON assets
    FOR UPDATE
    USING (auth.uid() = user_id);

-- Policy: Users can only delete their own assets
CREATE POLICY assets_delete_policy ON assets
    FOR DELETE
    USING (auth.uid() = user_id);

-- Enable RLS on wealth_history table
ALTER TABLE wealth_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own wealth history
CREATE POLICY wealth_history_select_policy ON wealth_history
    FOR SELECT
    USING (auth.uid() = user_id);

-- Policy: Users can only insert their own wealth history
CREATE POLICY wealth_history_insert_policy ON wealth_history
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- REALTIME
-- ============================================================================

-- Enable Realtime for assets table
ALTER PUBLICATION supabase_realtime ADD TABLE assets;

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to calculate total net worth for a user
CREATE OR REPLACE FUNCTION calculate_user_net_worth(p_user_id UUID)
RETURNS DECIMAL(20, 2) AS $$
DECLARE
    total_net_worth DECIMAL(20, 2);
BEGIN
    SELECT COALESCE(SUM(balance_usd), 0.00)
    INTO total_net_worth
    FROM assets
    WHERE user_id = p_user_id;
    
    RETURN total_net_worth;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to record wealth snapshot
CREATE OR REPLACE FUNCTION record_wealth_snapshot(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    current_net_worth DECIMAL(20, 2);
BEGIN
    -- Calculate current net worth
    current_net_worth := calculate_user_net_worth(p_user_id);
    
    -- Insert into wealth history
    INSERT INTO wealth_history (user_id, total_amount, timestamp)
    VALUES (p_user_id, current_net_worth, NOW())
    ON CONFLICT (user_id, timestamp) 
    DO UPDATE SET total_amount = EXCLUDED.total_amount;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE assets IS 'Stores all user financial assets including crypto wallets and bank accounts';
COMMENT ON TABLE wealth_history IS 'Time-series data for tracking total wealth over time';
COMMENT ON COLUMN assets.asset_address_or_id IS 'Wallet address for crypto or account ID for bank accounts';
COMMENT ON COLUMN assets.balance_usd IS 'Current balance in USD';
COMMENT ON COLUMN assets.last_sync IS 'Timestamp of last synchronization with provider';
