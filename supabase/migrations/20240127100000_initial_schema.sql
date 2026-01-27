-- ============================================================================
-- FINANCO PORTFOLIO TRACKER - COMPLETE DATABASE MIGRATION
-- ============================================================================
-- Version: 1.0.0
-- Date: 2024-01-27
-- Author: Finance Realtime Engine
-- Description: Complete schema for unified portfolio management with crypto, stocks, and banking
-- ============================================================================

-- ============================================================================
-- SECTION 1: ENUMS (TYPES DE DONNÉES)
-- ============================================================================

-- Types d'actifs supportés
CREATE TYPE asset_type AS ENUM (
  'crypto',      -- Cryptomonnaies
  'stock',       -- Actions
  'cash',        -- Comptes bancaires
  'investment',  -- Investissements (401k, IRA, etc.)
  'real_estate', -- Immobilier
  'commodity',   -- Matières premières (Or, Argent, etc.)
  'liability',   -- Dettes (crédits, prêts)
  'other'        -- Autres actifs
);

-- Fournisseurs de données
CREATE TYPE asset_provider AS ENUM (
  'moralis',     -- Données crypto via Moralis
  'fmp',         -- Données actions via Financial Modeling Prep
  'plaid',       -- Données bancaires via Plaid
  'manual'       -- Saisie manuelle
);

-- Statuts des actifs
CREATE TYPE asset_status AS ENUM (
  'active',      -- Actif actif et suivi
  'inactive',    -- Actif inactif (supprimé mais conservé pour l'historique)
  'pending'      -- En attente de validation
);

-- ============================================================================
-- SECTION 2: TABLES PRINCIPALES
-- ============================================================================

-- Table des actifs (tous types confondus)
CREATE TABLE assets (
  -- IDENTIFICATION
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- IDENTIFICATION DE L'ACTIF
  asset_address_or_id TEXT NOT NULL,
  provider asset_provider NOT NULL,
  type asset_type NOT NULL,
  
  -- INFORMATIONS GÉNÉRALES
  name TEXT NOT NULL,
  symbol TEXT,
  icon_url TEXT,
  
  -- VALEURS FINANCIÈRES
  quantity NUMERIC DEFAULT 0,
  current_price NUMERIC,
  price_usd NUMERIC,
  balance_usd NUMERIC GENERATED ALWAYS AS (
    CASE 
      WHEN current_price IS NOT NULL AND quantity IS NOT NULL THEN current_price * quantity
      WHEN price_usd IS NOT NULL AND quantity IS NOT NULL THEN price_usd * quantity
      ELSE balance_usd_manual
    END
  ) STORED,
  balance_usd_manual NUMERIC,
  
  -- PERFORMANCE
  change_24h NUMERIC,
  realized_pnl_usd NUMERIC DEFAULT 0,
  realized_pnl_percent NUMERIC DEFAULT 0,
  
  -- MÉTADONNÉES
  country TEXT,
  sector TEXT,
  industry TEXT,
  currency TEXT DEFAULT 'USD',
  
  -- SUIVI
  last_sync TIMESTAMPTZ,
  status asset_status DEFAULT 'active',
  
  -- TIMESTAMPS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- CONTRAINTES
  UNIQUE(user_id, provider, asset_address_or_id)
);

COMMENT ON TABLE assets IS 'Table principale regroupant tous les actifs des utilisateurs (crypto, actions, bancaire, etc.)';
COMMENT ON COLUMN assets.asset_address_or_id IS 'Identifiant unique selon le provider (ex: "0xabc...:native:eth", "fmp:AAPL", "plaid:item-123:account-456")';
COMMENT ON COLUMN assets.balance_usd IS 'Valeur totale calculée automatiquement en USD';
COMMENT ON COLUMN assets.realized_pnl_usd IS 'Profit/Perte réalisé en USD (pour crypto via Moralis)';
COMMENT ON COLUMN assets.realized_pnl_percent IS 'Pourcentage de profit/perte réalisé';

-- Table des snapshots de richesse (pour tracking quotidien)
CREATE TABLE wealth_snapshots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- VALEURS TOTALES
  total_value_usd NUMERIC NOT NULL,
  crypto_value NUMERIC DEFAULT 0,
  stock_value NUMERIC DEFAULT 0,
  cash_value NUMERIC DEFAULT 0,
  investment_value NUMERIC DEFAULT 0,
  other_value NUMERIC DEFAULT 0,
  
  -- MÉTRIQUES
  asset_count INTEGER DEFAULT 0,
  diversification_score NUMERIC DEFAULT 0,
  
  -- DATE
  snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- TIMESTAMPS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- CONTRAINTES
  UNIQUE(user_id, snapshot_date)
);

COMMENT ON TABLE wealth_snapshots IS 'Snapshots quotidiens de la richesse pour calculer les changements journaliers';
COMMENT ON COLUMN wealth_snapshots.diversification_score IS 'Score de diversification (0-10) calculé au moment du snapshot';

-- Table des tokens Plaid (stockage sécurisé)
CREATE TABLE plaid_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- IDENTIFICATION PLAID
  item_id TEXT NOT NULL,
  institution_name TEXT,
  
  -- TOKENS CHIFFRÉS
  access_token_encrypted TEXT NOT NULL,
  iv TEXT NOT NULL,
  
  -- SUIVI
  last_synced TIMESTAMPTZ,
  
  -- TIMESTAMPS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- CONTRAINTES
  UNIQUE(user_id, item_id)
);

COMMENT ON TABLE plaid_items IS 'Tokens d''accès Plaid chiffrés pour les connexions bancaires';
COMMENT ON COLUMN plaid_items.access_token_encrypted IS 'Token d''accès Plaid chiffré avec AES-GCM';
COMMENT ON COLUMN plaid_items.iv IS 'Vecteur d''initialisation pour le déchiffrement';

-- Table de suivi des synchronisations
CREATE TABLE user_sync_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  
  -- DATES DE SYNCHRO
  last_crypto_sync TIMESTAMPTZ,
  last_stock_sync TIMESTAMPTZ,
  last_bank_sync TIMESTAMPTZ,
  last_full_sync TIMESTAMPTZ,
  
  -- STATUTS
  crypto_sync_status TEXT DEFAULT 'pending',
  stock_sync_status TEXT DEFAULT 'pending',
  bank_sync_status TEXT DEFAULT 'pending',
  
  -- MÉTRIQUES
  crypto_assets_count INTEGER DEFAULT 0,
  stock_assets_count INTEGER DEFAULT 0,
  bank_assets_count INTEGER DEFAULT 0,
  
  -- TIMESTAMPS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE user_sync_status IS 'Suivi de l''état des synchronisations pour chaque utilisateur';

-- Table des alertes et insights
CREATE TABLE portfolio_insights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- SCORES
  diversification_score NUMERIC DEFAULT 0,
  risk_score NUMERIC DEFAULT 0,
  volatility_score NUMERIC DEFAULT 0,
  
  -- ALERTES
  exposure_warnings JSONB DEFAULT '[]',
  concentration_warnings JSONB DEFAULT '[]',
  
  -- RECOMMANDATIONS
  recommendations JSONB DEFAULT '[]',
  
  -- PÉRIODE
  analysis_date DATE NOT NULL DEFAULT CURRENT_DATE,
  
  -- TIMESTAMPS
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- CONTRAINTES
  UNIQUE(user_id, analysis_date)
);

COMMENT ON TABLE portfolio_insights IS 'Insights et analyses de portefeuille calculés quotidiennement';

-- ============================================================================
-- SECTION 3: INDEXES POUR LES PERFORMANCES
-- ============================================================================

-- Index pour les assets
CREATE INDEX assets_user_id_idx ON assets(user_id);
CREATE INDEX assets_provider_idx ON assets(provider);
CREATE INDEX assets_type_idx ON assets(type);
CREATE INDEX assets_last_sync_idx ON assets(last_sync DESC);
CREATE INDEX assets_user_provider_idx ON assets(user_id, provider);
CREATE INDEX assets_user_status_idx ON assets(user_id, status);

-- Index pour wealth_snapshots
CREATE INDEX wealth_snapshots_user_id_idx ON wealth_snapshots(user_id);
CREATE INDEX wealth_snapshots_date_idx ON wealth_snapshots(snapshot_date DESC);
CREATE INDEX wealth_snapshots_user_date_idx ON wealth_snapshots(user_id, snapshot_date DESC);

-- Index pour plaid_items
CREATE INDEX plaid_items_user_id_idx ON plaid_items(user_id);
CREATE INDEX plaid_items_item_id_idx ON plaid_items(item_id);

-- Index pour user_sync_status
CREATE INDEX user_sync_status_last_full_sync_idx ON user_sync_status(last_full_sync DESC);

-- Index pour portfolio_insights
CREATE INDEX portfolio_insights_user_id_idx ON portfolio_insights(user_id);
CREATE INDEX portfolio_insights_analysis_date_idx ON portfolio_insights(analysis_date DESC);

-- ============================================================================
-- SECTION 4: FUNCTIONS ET PROCEDURES
-- ============================================================================

-- Fonction pour enregistrer un snapshot de richesse
CREATE OR REPLACE FUNCTION record_wealth_snapshot(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_total NUMERIC;
  v_crypto NUMERIC;
  v_stock NUMERIC;
  v_cash NUMERIC;
  v_investment NUMERIC;
  v_other NUMERIC;
  v_asset_count INTEGER;
  v_diversification_score NUMERIC;
BEGIN
  -- Calcul des valeurs par type
  SELECT 
    COALESCE(SUM(balance_usd), 0),
    COALESCE(SUM(CASE WHEN type = 'crypto' THEN balance_usd ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'stock' THEN balance_usd ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'cash' THEN balance_usd ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type = 'investment' THEN balance_usd ELSE 0 END), 0),
    COALESCE(SUM(CASE WHEN type NOT IN ('crypto', 'stock', 'cash', 'investment') THEN balance_usd ELSE 0 END), 0),
    COUNT(*)
  INTO v_total, v_crypto, v_stock, v_cash, v_investment, v_other, v_asset_count
  FROM assets 
  WHERE user_id = p_user_id 
    AND status = 'active'
    AND balance_usd IS NOT NULL
    AND balance_usd > 0
    AND last_sync > NOW() - INTERVAL '7 days';
  
  -- Calcul du score de diversification simple
  SELECT 
    CASE 
      WHEN v_total = 0 THEN 0
      ELSE (
        (CASE WHEN v_crypto > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN v_stock > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN v_cash > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN v_investment > 0 THEN 1 ELSE 0 END) +
        (CASE WHEN v_other > 0 THEN 1 ELSE 0 END)
      ) * 2  -- 0-10 scale
    END
  INTO v_diversification_score;
  
  -- Insertion ou mise à jour du snapshot
  INSERT INTO wealth_snapshots (
    user_id, 
    total_value_usd,
    crypto_value,
    stock_value,
    cash_value,
    investment_value,
    other_value,
    asset_count,
    diversification_score,
    snapshot_date
  ) VALUES (
    p_user_id,
    v_total,
    v_crypto,
    v_stock,
    v_cash,
    v_investment,
    v_other,
    v_asset_count,
    v_diversification_score,
    CURRENT_DATE
  )
  ON CONFLICT (user_id, snapshot_date) 
  DO UPDATE SET
    total_value_usd = EXCLUDED.total_value_usd,
    crypto_value = EXCLUDED.crypto_value,
    stock_value = EXCLUDED.stock_value,
    cash_value = EXCLUDED.cash_value,
    investment_value = EXCLUDED.investment_value,
    other_value = EXCLUDED.other_value,
    asset_count = EXCLUDED.asset_count,
    diversification_score = EXCLUDED.diversification_score,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION record_wealth_snapshot IS 'Enregistre un snapshot de la richesse d''un utilisateur pour le tracking quotidien';

-- Fonction pour calculer le changement journalier
CREATE OR REPLACE FUNCTION get_daily_change(p_user_id UUID)
RETURNS TABLE (
  today_value NUMERIC,
  yesterday_value NUMERIC,
  change_amount NUMERIC,
  change_percentage NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  WITH today AS (
    SELECT total_value_usd, snapshot_date
    FROM wealth_snapshots
    WHERE user_id = p_user_id 
      AND snapshot_date = CURRENT_DATE
    LIMIT 1
  ),
  yesterday AS (
    SELECT total_value_usd, snapshot_date
    FROM wealth_snapshots
    WHERE user_id = p_user_id 
      AND snapshot_date = CURRENT_DATE - INTERVAL '1 day'
    LIMIT 1
  )
  SELECT 
    COALESCE(t.total_value_usd, 0) as today_value,
    COALESCE(y.total_value_usd, 0) as yesterday_value,
    COALESCE(t.total_value_usd, 0) - COALESCE(y.total_value_usd, 0) as change_amount,
    CASE 
      WHEN COALESCE(y.total_value_usd, 0) = 0 THEN 0
      ELSE ((COALESCE(t.total_value_usd, 0) - COALESCE(y.total_value_usd, 0)) / COALESCE(y.total_value_usd, 0)) * 100
    END as change_percentage
  FROM today t
  CROSS JOIN yesterday y;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_daily_change IS 'Calcule le changement de richesse entre aujourd''hui et hier';

-- Fonction pour nettoyer les anciens snapshots (garder 90 jours)
CREATE OR REPLACE FUNCTION cleanup_old_snapshots()
RETURNS void AS $$
BEGIN
  DELETE FROM wealth_snapshots 
  WHERE snapshot_date < CURRENT_DATE - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION cleanup_old_snapshots IS 'Nettoie les snapshots de plus de 90 jours';

-- Fonction pour mettre à jour le timestamp updated_at automatiquement
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Met à jour automatiquement la colonne updated_at';

-- ============================================================================
-- SECTION 5: TRIGGERS
-- ============================================================================

-- Trigger pour la table assets
CREATE TRIGGER update_assets_updated_at
BEFORE UPDATE ON assets
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour la table wealth_snapshots
CREATE TRIGGER update_wealth_snapshots_updated_at
BEFORE UPDATE ON wealth_snapshots
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour la table plaid_items
CREATE TRIGGER update_plaid_items_updated_at
BEFORE UPDATE ON plaid_items
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour la table user_sync_status
CREATE TRIGGER update_user_sync_status_updated_at
BEFORE UPDATE ON user_sync_status
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour la table portfolio_insights
CREATE TRIGGER update_portfolio_insights_updated_at
BEFORE UPDATE ON portfolio_insights
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour mettre à jour user_sync_status quand un asset est ajouté/modifié
CREATE OR REPLACE FUNCTION update_user_sync_on_asset_change()
RETURNS TRIGGER AS $$
BEGIN
  -- Mettre à jour le user_sync_status
  INSERT INTO user_sync_status (user_id, last_full_sync)
  VALUES (NEW.user_id, NOW())
  ON CONFLICT (user_id) 
  DO UPDATE SET
    last_full_sync = NOW(),
    updated_at = NOW();
    
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_sync_on_asset_change
AFTER INSERT OR UPDATE ON assets
FOR EACH ROW
EXECUTE FUNCTION update_user_sync_on_asset_change();

-- ============================================================================
-- SECTION 6: VIEWS POUR L'ANALYSE
-- ============================================================================

-- Vue pour le networth unifié
CREATE OR REPLACE VIEW unified_networth AS
SELECT 
  a.user_id,
  SUM(a.balance_usd) as total_networth,
  COUNT(*) as total_assets,
  JSONB_AGG(
    JSONB_BUILD_OBJECT(
      'id', a.id,
      'name', a.name,
      'type', a.type,
      'provider', a.provider,
      'symbol', a.symbol,
      'value', a.balance_usd,
      'change_24h', a.change_24h,
      'last_sync', a.last_sync
    ) ORDER BY a.balance_usd DESC
  ) as assets_details
FROM assets a
WHERE a.status = 'active'
  AND a.balance_usd > 0
GROUP BY a.user_id;

COMMENT ON VIEW unified_networth IS 'Vue unifiée de la richesse totale par utilisateur';

-- Vue pour la répartition des actifs par type
CREATE OR REPLACE VIEW asset_allocation_by_type AS
SELECT 
  user_id,
  type,
  SUM(balance_usd) as total_value,
  COUNT(*) as asset_count,
  ROUND((SUM(balance_usd) / NULLIF(SUM(SUM(balance_usd)) OVER (PARTITION BY user_id), 0)) * 100, 2) as percentage
FROM assets
WHERE status = 'active'
  AND balance_usd > 0
GROUP BY user_id, type
ORDER BY user_id, total_value DESC;

COMMENT ON VIEW asset_allocation_by_type IS 'Répartition des actifs par type pour chaque utilisateur';

-- Vue pour la performance quotidienne
CREATE OR REPLACE VIEW daily_performance AS
SELECT 
  w.user_id,
  w.snapshot_date,
  w.total_value_usd,
  LAG(w.total_value_usd) OVER (PARTITION BY w.user_id ORDER BY w.snapshot_date) as previous_value,
  w.total_value_usd - LAG(w.total_value_usd) OVER (PARTITION BY w.user_id ORDER BY w.snapshot_date) as daily_change,
  CASE 
    WHEN LAG(w.total_value_usd) OVER (PARTITION BY w.user_id ORDER BY w.snapshot_date) = 0 THEN 0
    ELSE ROUND(((w.total_value_usd - LAG(w.total_value_usd) OVER (PARTITION BY w.user_id ORDER BY w.snapshot_date)) / 
           LAG(w.total_value_usd) OVER (PARTITION BY w.user_id ORDER BY w.snapshot_date)) * 100, 2)
  END as daily_change_percentage
FROM wealth_snapshots w
ORDER BY w.user_id, w.snapshot_date DESC;

COMMENT ON VIEW daily_performance IS 'Performance quotidienne de la richesse';

-- Vue pour les insights de diversification
CREATE OR REPLACE VIEW diversification_insights AS
SELECT 
  user_id,
  snapshot_date,
  diversification_score,
  CASE 
    WHEN diversification_score >= 8 THEN 'Excellent'
    WHEN diversification_score >= 6 THEN 'Bon'
    WHEN diversification_score >= 4 THEN 'Moyen'
    ELSE 'À améliorer'
  END as score_label,
  crypto_value,
  stock_value,
  cash_value,
  investment_value,
  other_value,
  total_value_usd
FROM wealth_snapshots
ORDER BY user_id, snapshot_date DESC;

COMMENT ON VIEW diversification_insights IS 'Insights sur la diversification du portefeuille';

-- ============================================================================
-- SECTION 7: POLICIES RLS (ROW LEVEL SECURITY)
-- ============================================================================

-- Activer RLS sur toutes les tables
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wealth_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE plaid_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_sync_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE portfolio_insights ENABLE ROW LEVEL SECURITY;

-- Policies pour la table assets
CREATE POLICY "Users can view their own assets" ON assets
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own assets" ON assets
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own assets" ON assets
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own assets" ON assets
FOR DELETE USING (auth.uid() = user_id);

-- Policies pour la table wealth_snapshots
CREATE POLICY "Users can view their own snapshots" ON wealth_snapshots
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own snapshots" ON wealth_snapshots
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policies pour la table plaid_items
CREATE POLICY "Users can view their own plaid items" ON plaid_items
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own plaid items" ON plaid_items
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plaid items" ON plaid_items
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plaid items" ON plaid_items
FOR DELETE USING (auth.uid() = user_id);

-- Policies pour la table user_sync_status
CREATE POLICY "Users can view their own sync status" ON user_sync_status
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own sync status" ON user_sync_status
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own sync status" ON user_sync_status
FOR UPDATE USING (auth.uid() = user_id);

-- Policies pour la table portfolio_insights
CREATE POLICY "Users can view their own insights" ON portfolio_insights
FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own insights" ON portfolio_insights
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- SECTION 8: DONNÉES DE TEST (OPTIONNEL - POUR DÉVELOPPEMENT)
-- ============================================================================

-- Insérer des données de test (commenté en production)
/*
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
VALUES 
  ('11111111-1111-1111-1111-111111111111', 'test@financo.app', '', NOW(), NOW(), NOW())
ON CONFLICT DO NOTHING;

-- Ajouter des actifs de test
INSERT INTO assets (
  user_id, asset_address_or_id, provider, type, name, symbol, 
  quantity, current_price, balance_usd, change_24h, last_sync
) VALUES
  -- Crypto
  ('11111111-1111-1111-1111-111111111111', '0xtest:native:eth', 'moralis', 'crypto', 'Ethereum', 'ETH', 
   1.5, 2200.00, 3300.00, 2.5, NOW()),
  
  -- Actions
  ('11111111-1111-1111-1111-111111111111', 'fmp:AAPL', 'fmp', 'stock', 'Apple Inc.', 'AAPL', 
   10, 182.63, 1826.30, -1.2, NOW()),
  
  -- Bancaire
  ('11111111-1111-1111-1111-111111111111', 'plaid:item-test:account-123', 'plaid', 'cash', 'Chase Checking', 'USD', 
   1, 5420.50, 5420.50, 0, NOW())
ON CONFLICT DO NOTHING;

-- Créer un snapshot de test
SELECT record_wealth_snapshot('11111111-1111-1111-1111-111111111111');
*/