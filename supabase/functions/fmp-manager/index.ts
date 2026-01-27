// Supabase Edge Function: fmp-manager
// Purpose: Search stocks, fetch real-time prices, and save enriched assets to database
// Author: Finance Realtime Engine

// fmp-manager.ts - REFACTORED FOR UNIFIED PORTFOLIO MANAGEMENT
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const FMP_API_KEY = Deno.env.get('FMP_API_KEY');
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const BASE_URL = "https://financialmodelingprep.com/api/v3";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================================================
// TYPES
// ============================================================================

interface FMPProfile {
  symbol: string;
  companyName: string;
  price: number;
  changes: number;
  changePercentage: number;
  sector: string;
  industry: string;
  country: string;
  image: string;
  exchange: string;
  mktCap: number;
  beta: number;
  volAvg: number;
  lastDiv: number;
  range: string;
  currency: string;
  isEtf: boolean;
  isActivelyTrading: boolean;
}

interface FMPQuote {
  symbol: string;
  name: string;
  price: number;
  changesPercentage: number;
  change: number;
  dayLow: number;
  dayHigh: number;
  yearHigh: number;
  yearLow: number;
  marketCap: number;
  priceAvg50: number;
  priceAvg200: number;
  exchange: string;
  volume: number;
  avgVolume: number;
  open: number;
  previousClose: number;
  eps: number;
  pe: number;
  earningsAnnouncement: string;
  sharesOutstanding: number;
  timestamp: number;
}

interface FMPSearchResult {
  symbol: string;
  name: string;
  currency: string;
  stockExchange: string;
  exchangeShortName: string;
}

interface RequestPayload {
  action: 'search' | 'get_quotes' | 'get_profile' | 'add_asset' | 'update_prices' | 'remove_asset';
  query?: string;
  symbols?: string;
  symbol?: string;
  userId?: string;
  quantity?: number;
  assetId?: string;
}

// ============================================================================
// FMP API HELPERS
// ============================================================================

/**
 * Fetch stock profile from FMP API
 */
async function fetchStockProfile(symbol: string): Promise<FMPProfile | null> {
  try {
    const response = await fetch(`${BASE_URL}/profile/${symbol.toUpperCase()}?apikey=${FMP_API_KEY}`);
    
    if (!response.ok) {
      throw new Error(`FMP API error: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (!data || data.length === 0) {
      throw new Error(`No profile found for symbol: ${symbol}`);
    }
    
    return data[0];
  } catch (error) {
    console.error(`Failed to fetch profile for ${symbol}:`, error);
    throw error;
  }
}

/**
 * Fetch real-time quotes for multiple symbols
 */
async function fetchQuotes(symbols: string): Promise<FMPQuote[]> {
  try {
    const response = await fetch(`${BASE_URL}/quote/${symbols.toUpperCase()}?apikey=${FMP_API_KEY}`);
    
    if (!response.ok) {
      throw new Error(`FMP API error: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (!Array.isArray(data)) {
      throw new Error('Invalid response format from FMP API');
    }
    
    return data;
  } catch (error) {
    console.error(`Failed to fetch quotes for ${symbols}:`, error);
    throw error;
  }
}

/**
 * Search for stocks by query
 */
async function searchStocks(query: string): Promise<FMPSearchResult[]> {
  try {
    const response = await fetch(`${BASE_URL}/search?query=${encodeURIComponent(query)}&limit=15&apikey=${FMP_API_KEY}`);
    
    if (!response.ok) {
      throw new Error(`FMP API error: ${response.status}`);
    }
    
    const data = await response.json();
    
    if (!Array.isArray(data)) {
      throw new Error('Invalid response format from FMP API');
    }
    
    // Filter out invalid or empty results
    return data.filter(item => 
      item.symbol && 
      item.name && 
      !item.symbol.includes('.') && // Filter out foreign exchanges for simplicity
      item.currency === 'USD'
    );
  } catch (error) {
    console.error(`Failed to search for ${query}:`, error);
    throw error;
  }
}

/**
 * Process stock data for database insertion
 */
function processStockForUpsert(
  profile: FMPProfile,
  quantity: number,
  userId: string
): any {
  const price = profile.price || 0;
  const balanceUsd = price * quantity;
  const change24h = profile.changesPercentage || 0;
  
  return {
    user_id: userId,
    asset_address_or_id: `fmp:${profile.symbol.toUpperCase()}`,
    provider: 'fmp',
    type: 'stock',
    symbol: profile.symbol.toUpperCase(),
    name: profile.companyName,
    icon_url: profile.image || null,
    quantity: quantity,
    current_price: price,
    price_usd: price,
    balance_usd: balanceUsd,
    change_24h: change24h,
    sector: profile.sector || null,
    industry: profile.industry || null,
    country: profile.country || 'US',
    last_sync: new Date().toISOString(),
  };
}

/**
 * Update prices for existing FMP assets
 */
async function updateStockPrices(
  supabase: any,
  userId: string
): Promise<{ updated: number; failed: number }> {
  try {
    // Fetch all FMP assets for the user
    const { data: assets, error: fetchError } = await supabase
      .from('assets')
      .select('symbol, id')
      .eq('user_id', userId)
      .eq('provider', 'fmp')
      .eq('type', 'stock');
    
    if (fetchError) {
      throw new Error(`Failed to fetch assets: ${fetchError.message}`);
    }
    
    if (!assets || assets.length === 0) {
      return { updated: 0, failed: 0 };
    }
    
    // Extract symbols and batch them (FMP allows up to 10 symbols per request for free tier)
    const symbols = assets.map(asset => asset.symbol);
    const symbolBatches = [];
    
    for (let i = 0; i < symbols.length; i += 10) {
      symbolBatches.push(symbols.slice(i, i + 10));
    }
    
    let updatedCount = 0;
    let failedCount = 0;
    
    // Process each batch
    for (const batch of symbolBatches) {
      const symbolsString = batch.join(',');
      
      try {
        const quotes = await fetchQuotes(symbolsString);
        
        // Update each asset with new price
        for (const quote of quotes) {
          const asset = assets.find(a => a.symbol === quote.symbol);
          
          if (asset) {
            const { error: updateError } = await supabase
              .from('assets')
              .update({
                current_price: quote.price,
                price_usd: quote.price,
                balance_usd: quote.price * (await getAssetQuantity(supabase, asset.id)),
                change_24h: quote.changesPercentage,
                last_sync: new Date().toISOString(),
              })
              .eq('id', asset.id);
            
            if (updateError) {
              console.error(`Failed to update ${quote.symbol}:`, updateError);
              failedCount++;
            } else {
              updatedCount++;
            }
          }
        }
      } catch (error) {
        console.error(`Failed to process batch ${symbolsString}:`, error);
        failedCount += batch.length;
      }
    }
    
    // Record snapshot after price update
    try {
      await supabase.rpc('record_wealth_snapshot', { p_user_id: userId });
    } catch (snapshotError) {
      console.warn('Failed to record snapshot after price update:', snapshotError);
    }
    
    return { updated: updatedCount, failed: failedCount };
  } catch (error) {
    console.error('Error updating stock prices:', error);
    throw error;
  }
}

/**
 * Get current quantity of an asset
 */
async function getAssetQuantity(supabase: any, assetId: string): Promise<number> {
  const { data, error } = await supabase
    .from('assets')
    .select('quantity')
    .eq('id', assetId)
    .single();
  
  if (error || !data) {
    return 0;
  }
  
  return parseFloat(data.quantity) || 0;
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: RequestPayload = await req.json();
    const { action, query, symbols, symbol, userId, quantity, assetId } = payload;
    
    // Initialize Supabase Client
    const supabase = createClient(SUPABASE_URL!, SUPABASE_SERVICE_ROLE_KEY!);

    switch (action) {
      case 'search': {
        if (!query) throw new Error('Query parameter is required');
        
        console.log(`Searching stocks for query: ${query}`);
        const results = await searchStocks(query);
        
        return new Response(JSON.stringify(results), { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      case 'get_quotes': {
        if (!symbols) throw new Error('Symbols parameter is required');
        
        console.log(`Fetching quotes for symbols: ${symbols}`);
        const quotes = await fetchQuotes(symbols);
        
        return new Response(JSON.stringify(quotes), { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      case 'get_profile': {
        if (!symbol) throw new Error('Symbol parameter is required');
        
        console.log(`Fetching profile for symbol: ${symbol}`);
        const profile = await fetchStockProfile(symbol);
        
        return new Response(JSON.stringify(profile), { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        });
      }

      case 'add_asset': {
        if (!userId || !symbol || !quantity) {
          throw new Error('userId, symbol, and quantity are required');
        }
        
        console.log(`Adding stock ${symbol} for user ${userId}, quantity: ${quantity}`);
        
        // 1. Fetch stock profile from FMP
        const profile = await fetchStockProfile(symbol);
        
        if (!profile) {
          throw new Error(`Stock profile not found for symbol: ${symbol}`);
        }
        
        // 2. Check if asset already exists for this user
        const assetAddress = `fmp:${profile.symbol.toUpperCase()}`;
        const { data: existingAssets } = await supabase
          .from('assets')
          .select('*')
          .eq('user_id', userId)
          .eq('asset_address_or_id', assetAddress)
          .maybeSingle();
        
        let finalQuantity = quantity;
        
        // 3. If exists, add to existing quantity
        if (existingAssets) {
          finalQuantity = parseFloat(existingAssets.quantity) + quantity;
          console.log(`Asset exists, updating quantity from ${existingAssets.quantity} to ${finalQuantity}`);
        }
        
        // 4. Prepare data for upsert
        const assetData = processStockForUpsert(profile, finalQuantity, userId);
        
        // 5. Upsert to database
        const { error: dbError } = await supabase
          .from('assets')
          .upsert(assetData, { 
            onConflict: 'asset_address_or_id, user_id',
            ignoreDuplicates: false
          });
        
        if (dbError) {
          console.error('Database upsert error:', dbError);
          throw new Error(`Failed to save asset: ${dbError.message}`);
        }
        
        console.log(`Successfully added/updated stock: ${profile.symbol}`);
        
        // 6. Record wealth snapshot
        try {
          await supabase.rpc('record_wealth_snapshot', { p_user_id: userId });
          console.log(`Recorded snapshot for user ${userId}`);
        } catch (snapshotError) {
          console.warn('Failed to record snapshot:', snapshotError);
        }
        
        return new Response(
          JSON.stringify({ 
            success: true, 
            message: 'Asset added successfully',
            asset: {
              symbol: profile.symbol,
              name: profile.companyName,
              quantity: finalQuantity,
              price: profile.price,
              value: profile.price * finalQuantity,
              sector: profile.sector,
              country: profile.country
            }
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        );
      }

      case 'update_prices': {
        if (!userId) throw new Error('userId is required');
        
        console.log(`Updating stock prices for user ${userId}`);
        
        const { updated, failed } = await updateStockPrices(supabase, userId);
        
        return new Response(
          JSON.stringify({
            success: true,
            updated: updated,
            failed: failed,
            message: `Updated ${updated} stocks, ${failed} failed`
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        );
      }

      case 'remove_asset': {
        if (!userId || !assetId) {
          throw new Error('userId and assetId are required');
        }
        
        console.log(`Removing asset ${assetId} for user ${userId}`);
        
        // Verify the asset belongs to the user
        const { data: asset, error: fetchError } = await supabase
          .from('assets')
          .select('*')
          .eq('id', assetId)
          .eq('user_id', userId)
          .single();
        
        if (fetchError || !asset) {
          throw new Error('Asset not found or does not belong to user');
        }
        
        // Delete the asset
        const { error: deleteError } = await supabase
          .from('assets')
          .delete()
          .eq('id', assetId)
          .eq('user_id', userId);
        
        if (deleteError) {
          throw new Error(`Failed to delete asset: ${deleteError.message}`);
        }
        
        // Record snapshot after removal
        try {
          await supabase.rpc('record_wealth_snapshot', { p_user_id: userId });
        } catch (snapshotError) {
          console.warn('Failed to record snapshot after removal:', snapshotError);
        }
        
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Asset removed successfully',
            removed_asset: asset.symbol
          }), {
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            status: 200,
          }
        );
      }

      default:
        throw new Error(`Invalid action: ${action}`);
    }

  } catch (error) {
    console.error('FMP Manager Error:', error);
    
    return new Response(
      JSON.stringify({ 
        error: 'Internal Error', 
        message: error.message,
        action: (await req.json()).action 
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    );
  }
});