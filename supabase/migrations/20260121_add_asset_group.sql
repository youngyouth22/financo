-- Migration: Add asset_group column to assets table
-- Description: Add asset group categorization for dashboard (crypto, stocks, cash)
-- Author: Finance Realtime Engine
-- Date: 2026-01-21

-- ============================================================================
-- ADD ASSET GROUP ENUM
-- ============================================================================

-- Asset group enumeration for dashboard categorization
CREATE TYPE asset_group AS ENUM ('crypto', 'stocks', 'cash');

-- ============================================================================
-- ALTER ASSETS TABLE
-- ============================================================================

-- Add asset_group column
ALTER TABLE assets 
ADD COLUMN asset_group asset_group NOT NULL DEFAULT 'crypto';

-- Update existing records based on type
-- Crypto assets → crypto group
-- Bank assets → cash group
UPDATE assets 
SET asset_group = CASE 
    WHEN type = 'crypto' THEN 'crypto'::asset_group
    WHEN type = 'bank' THEN 'cash'::asset_group
    ELSE 'cash'::asset_group
END;

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Index for asset group queries
CREATE INDEX IF NOT EXISTS idx_assets_asset_group ON assets(asset_group);

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON COLUMN assets.asset_group IS 'Asset group for dashboard categorization: crypto, stocks, or cash';
COMMENT ON TYPE asset_group IS 'Enumeration for asset groups used in dashboard';
