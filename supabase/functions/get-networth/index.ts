// supabase/functions/get-networth/index.ts
// Unified Networth Calculator with Multiple Data Sources
// Author: Financo Portfolio Engine
// Version: 2.0.0

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const MORALIS_API_KEY = Deno.env.get("MORALIS_API_KEY");
const FMP_API_KEY = Deno.env.get("FMP_API_KEY");
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

// ============================================================================
// TYPES
// ============================================================================

interface AssetRecord {
  id: string;
  user_id: string;
  name: string;
  type: string;
  provider: string;
  balance_usd: number | string;
  asset_address_or_id: string;
  last_sync: string;
  realized_pnl_usd: number | string;
  realized_pnl_percent: number | string;
  symbol: string;
  quantity: number | string;
  current_price: number | string;
  change_24h: number | string;
  price_usd: number | string;
  icon_url: string;
  country: string;
  sector: string;
  industry: string;
  updated_at: string;
}

interface NetworthResponse {
  total: {
    value: number;
    currency: string;
    updated_at: string;
  };
  breakdown: {
    by_type: Record<string, number>;
    by_provider: Record<string, number>;
    by_country: Record<string, number>;
    by_sector: Record<string, number>;
  };
  performance: {
    daily_change: {
      amount: number;
      percentage: number;
      direction: 'up' | 'down' | 'neutral';
    };
    total_pnl: {
      realized_usd: number;
      realized_percent: number;
      estimated_24h: number;
    };
  };
  assets: Array<{
    id: string;
    name: string;
    symbol: string;
    type: string;
    provider: string;
    value: number;
    quantity: number;
    price: number;
    change_24h: number;
    pnl_usd: number;
    pnl_percent: number;
    icon_url: string;
    country: string;
    sector: string;
    last_updated: string;
  }>;
  insights: {
    diversification_score: number;
    risk_level: 'low' | 'medium' | 'high';
    concentration_warnings: string[];
    update_status: 'fresh' | 'stale' | 'mixed';
  };
}

// ============================================================================
// DIRECT API FETCHERS FOR ACCURACY
// ============================================================================

/**
 * Fetch crypto networth directly from Moralis API for maximum accuracy
 */
async function fetchDirectCryptoNetworth(address: string): Promise<{
  networth: number;
  breakdown: Array<{
    symbol: string;
    name: string;
    balance: number;
    value: number;
    type: string;
    change_24h: number;
  }>;
}> {
  if (!MORALIS_API_KEY) {
    console.warn("MORALIS_API_KEY not configured, skipping direct crypto fetch");
    return { networth: 0, breakdown: [] };
  }

  try {
    const options = {
      headers: { 
        "X-API-Key": MORALIS_API_KEY, 
        accept: "application/json" 
      },
    };

    // Fetch both networth and tokens in parallel
    const [networthRes, tokensRes] = await Promise.all([
      fetch(
        `https://deep-index.moralis.io/api/v2.2/wallets/${address}/net-worth?exclude_spam=true`,
        options,
      ),
      fetch(
        `https://deep-index.moralis.io/api/v2.2/wallets/${address}/tokens?exclude_spam=true&exclude_unverified_contracts=true`,
        options,
      ),
    ]);

    if (!networthRes.ok || !tokensRes.ok) {
      console.warn(`Moralis API error for ${address}: ${networthRes.status}/${tokensRes.status}`);
      return { networth: 0, breakdown: [] };
    }

    const networthData = await networthRes.json();
    const tokensData = await tokensRes.json();

    const totalNetworth = parseFloat(networthData.total_networth_usd || "0");
    const breakdown = [];

    // Process native assets
    if (networthData.chains) {
      for (const chain of networthData.chains) {
        const nativeValue = parseFloat(chain.native_balance_usd || "0");
        if (nativeValue > 0.1) {
          breakdown.push({
            symbol: chain.chain === "eth" ? "ETH" : chain.chain.toUpperCase(),
            name: `${chain.chain.toUpperCase()} Native`,
            balance: parseFloat(chain.native_balance_formatted),
            value: nativeValue,
            type: "crypto_native",
            change_24h: 0,
          });
        }
      }
    }

    // Process tokens
    const tokens = tokensData.result || [];
    for (const token of tokens) {
      const value = parseFloat(token.usd_value || "0");
      if (value > 1) {
        breakdown.push({
          symbol: token.symbol || "UNKNOWN",
          name: token.name || "Unknown Token",
          balance: parseFloat(token.balance_formatted),
          value: value,
          type: "crypto_token",
          change_24h: parseFloat(token.usd_price_24h_percent_change || "0"),
        });
      }
    }

    return {
      networth: totalNetworth,
      breakdown,
    };
  } catch (error) {
    console.error(`Failed to fetch direct crypto networth for ${address}:`, error);
    return { networth: 0, breakdown: [] };
  }
}

/**
 * Fetch updated stock prices directly from FMP API
 */
async function refreshStockPrices(
  symbols: string[]
): Promise<Record<string, { price: number; change: number }>> {
  if (!FMP_API_KEY || symbols.length === 0) {
    return {};
  }

  try {
    // FMP free tier allows 10 symbols per request
    const symbolBatches = [];
    for (let i = 0; i < symbols.length; i += 10) {
      symbolBatches.push(symbols.slice(i, i + 10));
    }

    const priceMap: Record<string, { price: number; change: number }> = {};

    for (const batch of symbolBatches) {
      const symbolsString = batch.join(',');
      const response = await fetch(
        `https://financialmodelingprep.com/api/v3/quote/${symbolsString}?apikey=${FMP_API_KEY}`
      );

      if (response.ok) {
        const quotes = await response.json();
        if (Array.isArray(quotes)) {
          for (const quote of quotes) {
            if (quote.symbol && quote.price) {
              priceMap[quote.symbol] = {
                price: quote.price,
                change: quote.changesPercentage || 0,
              };
            }
          }
        }
      }
    }

    return priceMap;
  } catch (error) {
    console.error("Failed to refresh stock prices:", error);
    return {};
  }
}

// ============================================================================
// INSIGHTS GENERATION
// ============================================================================

function generatePortfolioInsights(
  byType: Record<string, number>,
  byProvider: Record<string, number>,
  byCountry: Record<string, number>,
  bySector: Record<string, number>,
  totalValue: number,
  assets: AssetRecord[]
): {
  diversification_score: number;
  risk_level: 'low' | 'medium' | 'high';
  concentration_warnings: string[];
  update_status: 'fresh' | 'stale' | 'mixed';
} {
  const warnings: string[] = [];
  let staleCount = 0;
  let freshCount = 0;
  const now = new Date();

  // Check data freshness
  assets.forEach(asset => {
    if (asset.last_sync) {
      const lastSync = new Date(asset.last_sync);
      const hoursSinceSync = (now.getTime() - lastSync.getTime()) / (1000 * 60 * 60);
      
      if (hoursSinceSync > 24) staleCount++;
      else if (hoursSinceSync <= 1) freshCount++;
      else freshCount++; // Between 1-24 hours is considered fresh for our purposes
    }
  });

  const updateStatus = freshCount === assets.length ? 'fresh' :
                       staleCount === assets.length ? 'stale' : 'mixed';

  // Check crypto exposure
  const cryptoPercentage = ((byType['crypto'] || 0) / totalValue) * 100;
  if (cryptoPercentage > 50) {
    warnings.push(`High crypto exposure: ${cryptoPercentage.toFixed(1)}% of portfolio`);
  }

  // Check country concentration
  const countries = Object.entries(byCountry);
  if (countries.length > 0) {
    const topCountry = countries.sort((a, b) => b[1] - a[1])[0];
    const topCountryPercentage = (topCountry[1] / totalValue) * 100;
    
    if (topCountryPercentage > 60) {
      warnings.push(`Heavy concentration in ${topCountry[0]}: ${topCountryPercentage.toFixed(1)}%`);
    }
  }

  // Check sector concentration
  const sectors = Object.entries(bySector);
  if (sectors.length > 0) {
    const topSector = sectors.sort((a, b) => b[1] - a[1])[0];
    const topSectorPercentage = (topSector[1] / totalValue) * 100;
    
    if (topSectorPercentage > 40) {
      warnings.push(`Sector concentration in ${topSector[0]}: ${topSectorPercentage.toFixed(1)}%`);
    }
  }

  // Calculate diversification score (0-10)
  let diversificationScore = 0;
  if (totalValue > 0) {
    // Score based on number of asset types
    const typeCount = Object.keys(byType).length;
    diversificationScore += Math.min(5, typeCount);
    
    // Score based on provider diversity
    const providerCount = Object.keys(byProvider).length;
    diversificationScore += Math.min(3, providerCount);
    
    // Bonus for multiple countries and sectors
    if (countries.length > 1) diversificationScore += 1;
    if (sectors.length > 1) diversificationScore += 1;
    
    // Penalty for high concentration
    const maxTypePercentage = Math.max(...Object.values(byType)) / totalValue;
    if (maxTypePercentage > 0.7) {
      diversificationScore *= 0.7;
    }
    
    // Cap at 10
    diversificationScore = Math.min(10, diversificationScore);
  }

  // Risk level assessment
  let riskLevel: 'low' | 'medium' | 'high' = 'low';
  
  if (cryptoPercentage > 40 || warnings.length > 2 || updateStatus === 'stale') {
    riskLevel = 'high';
  } else if (cryptoPercentage > 20 || warnings.length > 0 || updateStatus === 'mixed') {
    riskLevel = 'medium';
  }

  return {
    diversification_score: Math.round(diversificationScore * 10) / 10,
    risk_level: riskLevel,
    concentration_warnings: warnings,
    update_status: updateStatus,
  };
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { userId, forceRefresh = false } = await req.json();
    
    if (!userId) {
      throw new Error("userId is required");
    }

    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);
    const now = new Date().toISOString();

    // 1. Fetch all assets from database
    const { data: assets, error: assetsError } = await supabase
      .from("assets")
      .select("*")
      .eq("user_id", userId)
      .eq("status", "active")
      .order("balance_usd", { ascending: false });

    if (assetsError) {
      throw new Error(`Failed to fetch assets: ${assetsError.message}`);
    }

    const assetRecords = assets as AssetRecord[];

    // 2. Refresh stock prices if needed or forced
    const stockSymbols = assetRecords
      .filter(asset => asset.provider === "fmp" && asset.symbol)
      .map(asset => asset.symbol);
    
    let stockPriceUpdates: Record<string, { price: number; change: number }> = {};
    
    if (forceRefresh && stockSymbols.length > 0) {
      console.log(`Refreshing prices for ${stockSymbols.length} stocks...`);
      stockPriceUpdates = await refreshStockPrices(stockSymbols);
      
      // Update database with fresh prices
      if (Object.keys(stockPriceUpdates).length > 0) {
        const updatePromises = assetRecords
          .filter(asset => asset.provider === "fmp" && stockPriceUpdates[asset.symbol])
          .map(async (asset) => {
            const update = stockPriceUpdates[asset.symbol];
            const quantity = parseFloat(asset.quantity.toString());
            const newValue = update.price * quantity;
            
            const { error } = await supabase
              .from("assets")
              .update({
                current_price: update.price,
                price_usd: update.price,
                balance_usd: newValue,
                change_24h: update.change,
                last_sync: now,
              })
              .eq("id", asset.id);
              
            if (error) {
              console.error(`Failed to update ${asset.symbol}:`, error);
            }
            
            return {
              ...asset,
              current_price: update.price,
              price_usd: update.price,
              balance_usd: newValue,
              change_24h: update.change,
              last_sync: now,
            };
          });
          
        await Promise.allSettled(updatePromises);
      }
    }

    // 3. Fetch direct crypto data for maximum accuracy
    const cryptoAddresses = new Set<string>();
    assetRecords.forEach(asset => {
      if (asset.provider === "moralis" && asset.asset_address_or_id) {
        const parts = asset.asset_address_or_id.split(':');
        if (parts.length > 0) {
          cryptoAddresses.add(parts[0]);
        }
      }
    });

    let directCryptoValue = 0;
    const directCryptoBreakdown: any[] = [];
    
    if (forceRefresh && cryptoAddresses.size > 0 && MORALIS_API_KEY) {
      console.log(`Fetching direct crypto data for ${cryptoAddresses.size} addresses...`);
      
      const cryptoPromises = Array.from(cryptoAddresses).map(async (address) => {
        try {
          const result = await fetchDirectCryptoNetworth(address);
          directCryptoValue += result.networth;
          directCryptoBreakdown.push(...result.breakdown.map(item => ({
            ...item,
            address,
          })));
          return result;
        } catch (error) {
          console.error(`Failed to fetch crypto for ${address}:`, error);
          return null;
        }
      });
      
      await Promise.allSettled(cryptoPromises);
    }

    // 4. Calculate totals and breakdowns
    let totalValue = 0;
    let totalRealizedPnl = 0;
    let totalEstimated24hChange = 0;
    
    const byType: Record<string, number> = {};
    const byProvider: Record<string, number> = {};
    const byCountry: Record<string, number> = {};
    const bySector: Record<string, number> = {};
    
    const enrichedAssets = assetRecords.map(asset => {
      // Use refreshed prices if available
      let value: number;
      let price: number;
      let change24h: number;
      
      if (asset.provider === "fmp" && stockPriceUpdates[asset.symbol]) {
        const update = stockPriceUpdates[asset.symbol];
        price = update.price;
        change24h = update.change;
        const quantity = parseFloat(asset.quantity.toString());
        value = price * quantity;
      } else {
        value = parseFloat(asset.balance_usd?.toString() || "0");
        price = parseFloat(asset.current_price?.toString() || asset.price_usd?.toString() || "0");
        change24h = parseFloat(asset.change_24h?.toString() || "0");
      }
      
      const pnlUsd = parseFloat(asset.realized_pnl_usd?.toString() || "0");
      const pnlPercent = parseFloat(asset.realized_pnl_percent?.toString() || "0");
      
      totalValue += value;
      totalRealizedPnl += pnlUsd;
      totalEstimated24hChange += value * (change24h / 100);
      
      // Aggregations
      byType[asset.type] = (byType[asset.type] || 0) + value;
      byProvider[asset.provider] = (byProvider[asset.provider] || 0) + value;
      
      if (asset.country) {
        byCountry[asset.country] = (byCountry[asset.country] || 0) + value;
      }
      
      if (asset.sector) {
        bySector[asset.sector] = (bySector[asset.sector] || 0) + value;
      }
      
      return {
        id: asset.id,
        name: asset.name,
        symbol: asset.symbol || 'N/A',
        type: asset.type,
        provider: asset.provider,
        value: value,
        quantity: parseFloat(asset.quantity?.toString() || "0"),
        price: price,
        change_24h: change24h,
        pnl_usd: pnlUsd,
        pnl_percent: pnlPercent,
        icon_url: asset.icon_url || '',
        country: asset.country || '',
        sector: asset.sector || '',
        last_updated: asset.last_sync || asset.updated_at,
      };
    });

    // 5. Add direct crypto data if available
    if (directCryptoValue > 0 && directCryptoBreakdown.length > 0) {
      totalValue += directCryptoValue;
      byType['crypto'] = (byType['crypto'] || 0) + directCryptoValue;
      byProvider['moralis'] = (byProvider['moralis'] || 0) + directCryptoValue;
      
      directCryptoBreakdown.forEach(item => {
        enrichedAssets.push({
          id: `direct-${item.symbol}-${Date.now()}`,
          name: item.name,
          symbol: item.symbol,
          type: 'crypto',
          provider: 'moralis_direct',
          value: item.value,
          quantity: item.balance,
          price: item.value / item.balance,
          change_24h: item.change_24h,
          pnl_usd: 0,
          pnl_percent: 0,
          icon_url: '',
          country: '',
          sector: '',
          last_updated: now,
        });
      });
    }

    // 6. Get daily change from snapshots
    const { data: changeData } = await supabase
      .rpc("get_daily_change", { p_user_id: userId });
    
    const dailyChange = changeData && changeData[0] ? {
      amount: parseFloat(changeData[0].change_amount) || 0,
      percentage: parseFloat(changeData[0].change_percentage) || 0,
      direction: parseFloat(changeData[0].change_percentage) > 0 ? 'up' : 
                parseFloat(changeData[0].change_percentage) < 0 ? 'down' : 'neutral'
    } : {
      amount: 0,
      percentage: 0,
      direction: 'neutral' as const
    };

    // 7. Generate insights
    const insights = generatePortfolioInsights(
      byType, 
      byProvider, 
      byCountry, 
      bySector, 
      totalValue,
      assetRecords
    );

    // 8. Build the final response
    const response: NetworthResponse = {
      total: {
        value: totalValue,
        currency: 'USD',
        updated_at: now,
      },
      breakdown: {
        by_type: byType,
        by_provider: byProvider,
        by_country: byCountry,
        by_sector: bySector,
      },
      performance: {
        daily_change: dailyChange,
        total_pnl: {
          realized_usd: totalRealizedPnl,
          realized_percent: totalValue > 0 ? (totalRealizedPnl / totalValue) * 100 : 0,
          estimated_24h: totalEstimated24hChange,
        },
      },
      assets: enrichedAssets.sort((a, b) => b.value - a.value),
      insights: insights,
    };

    // 9. Record a snapshot for tomorrow's comparison
    try {
      await supabase.rpc("record_wealth_snapshot", { p_user_id: userId });
    } catch (e) {
      console.warn("Failed to record snapshot:", e);
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  } catch (error) {
    console.error("get-networth error:", error);
    
    return new Response(
      JSON.stringify({ 
        error: "Internal Server Error", 
        message: error.message,
        action: 'get_networth'
      }),
      { 
        status: 500, 
        headers: { ...corsHeaders, "Content-Type": "application/json" } 
      }
    );
  }
});