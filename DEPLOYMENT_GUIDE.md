# Finance Realtime Engine - Deployment Guide

## Overview

This guide walks through the complete deployment process for the Finance Realtime Engine, including database setup, Edge Functions deployment, and Flutter app configuration.

## Prerequisites

- Supabase account and project
- Moralis account and API key
- Flutter SDK installed
- Supabase CLI installed
- Git configured

## Step 1: Database Setup

### 1.1 Run Migration

```bash
cd financo
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

This will create:
- `assets` table with RLS policies
- `wealth_history` table with RLS policies
- Helper functions (`calculate_user_net_worth`, `record_wealth_snapshot`)
- Realtime subscription on `assets` table

### 1.2 Verify Tables

```sql
-- Check if tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('assets', 'wealth_history');

-- Check if Realtime is enabled
SELECT * FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime';
```

## Step 2: Deploy Edge Functions

### 2.1 Deploy finance-webhook

```bash
supabase functions deploy finance-webhook
```

### 2.2 Deploy moralis-stream-manager

```bash
supabase functions deploy moralis-stream-manager
```

### 2.3 Set Environment Secrets

```bash
# Moralis API key
supabase secrets set MORALIS_API_KEY=your_moralis_api_key_here

# Moralis webhook secret (for signature verification)
supabase secrets set MORALIS_WEBHOOK_SECRET=your_webhook_secret_here

# Supabase service role key (if not auto-set)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key_here

# Finance webhook URL (optional, auto-detected)
supabase secrets set FINANCE_WEBHOOK_URL=https://YOUR_PROJECT_REF.supabase.co/functions/v1/finance-webhook
```

### 2.4 Verify Deployment

```bash
# Test finance-webhook
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/finance-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Expected response: {"success": true, "message": "Test webhook received"}

# Test moralis-stream-manager
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/moralis-stream-manager \
  -H "Content-Type: application/json" \
  -d '{"action": "setup"}'

# Expected response: {"success": true, "message": "Stream setup completed", ...}
```

## Step 3: Configure Moralis Stream

### 3.1 Setup Global Stream

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/moralis-stream-manager \
  -H "Content-Type: application/json" \
  -d '{
    "action": "setup"
  }'
```

This creates a global stream monitoring:
- Ethereum (0x1)
- Polygon (0x89)
- BSC (0x38)
- Avalanche (0xa86a)
- Arbitrum (0xa4b1)
- Optimism (0xa)
- Base (0x2105)

### 3.2 Verify Stream in Moralis Dashboard

1. Go to [Moralis Streams Dashboard](https://admin.moralis.io/streams)
2. Look for stream with tag `financo-global-stream`
3. Verify webhook URL is correct
4. Check that all chains are enabled

## Step 4: Flutter App Configuration

### 4.1 Update .env File

```bash
# .env
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_KEY=your_anon_key_here
```

### 4.2 Install Dependencies

```bash
flutter pub get
```

### 4.3 Run the App

```bash
flutter run
```

## Step 5: Testing the Complete Flow

### 5.1 Add a Test Wallet

```dart
// In your Flutter app
context.read<FinanceBloc>().add(
  AddAssetEvent(
    name: 'Test Ethereum Wallet',
    type: AssetType.crypto,
    provider: AssetProvider.moralis,
    assetAddressOrId: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb', // Vitalik's wallet
  ),
);
```

### 5.2 Verify Database Entry

```sql
SELECT * FROM assets WHERE asset_address_or_id = '0x742d35cc6634c0532925a3b844bc9e7595f0beb';
```

### 5.3 Verify Moralis Stream Registration

```bash
curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/moralis-stream-manager \
  -H "Content-Type: application/json" \
  -d '{
    "action": "setup"
  }'
```

Check the response for the stream ID, then verify addresses:

```bash
# Using Moralis API directly
curl -X GET "https://api.moralis-streams.com/streams/evm/YOUR_STREAM_ID/address" \
  -H "X-API-Key: YOUR_MORALIS_API_KEY"
```

### 5.4 Test Real-time Updates

1. Send a transaction to the monitored wallet
2. Wait for blockchain confirmation
3. Moralis webhook triggers Edge Function
4. Edge Function updates database
5. Supabase Realtime broadcasts change
6. Flutter app receives update automatically

### 5.5 Monitor Logs

```bash
# Watch Edge Function logs
supabase functions logs finance-webhook --tail

# Watch stream manager logs
supabase functions logs moralis-stream-manager --tail
```

## Step 6: Production Checklist

### Security

- [ ] RLS policies enabled on all tables
- [ ] Webhook signature verification enabled
- [ ] Service role key secured (never exposed to client)
- [ ] Environment variables properly set
- [ ] HTTPS enforced on all endpoints

### Performance

- [ ] Database indexes created
- [ ] Connection pooling configured
- [ ] Rate limiting enabled on Edge Functions
- [ ] Caching strategy implemented

### Monitoring

- [ ] Error tracking configured (e.g., Sentry)
- [ ] Performance monitoring enabled
- [ ] Log aggregation setup
- [ ] Alerting configured for critical errors

### Backup & Recovery

- [ ] Database backups enabled
- [ ] Point-in-time recovery configured
- [ ] Disaster recovery plan documented
- [ ] Regular backup testing scheduled

## Troubleshooting

### Issue: Webhook Not Receiving Events

**Solution:**
1. Verify webhook URL in Moralis dashboard
2. Check Edge Function logs for errors
3. Ensure MORALIS_WEBHOOK_SECRET is set correctly
4. Test webhook with curl

### Issue: Real-time Updates Not Working

**Solution:**
1. Verify Realtime is enabled on `assets` table
2. Check if user is authenticated
3. Ensure RLS policies allow SELECT
4. Test with Supabase Realtime inspector

### Issue: Asset Balance Not Updating

**Solution:**
1. Check if wallet has transactions on supported chains
2. Verify Moralis API key is valid
3. Check Edge Function logs for API errors
4. Manually trigger sync via `SyncAssetsEvent`

### Issue: Database Connection Errors

**Solution:**
1. Verify SUPABASE_URL and SUPABASE_KEY
2. Check if Supabase project is active
3. Ensure connection pooling limits not exceeded
4. Review RLS policies

## Monitoring & Maintenance

### Daily Checks

- Review Edge Function error logs
- Check webhook delivery success rate
- Monitor database performance metrics
- Verify Realtime subscription health

### Weekly Tasks

- Review asset sync accuracy
- Check for stale data (assets not synced in 24h)
- Analyze wealth history trends
- Update supported chain list if needed

### Monthly Tasks

- Review and optimize database queries
- Update dependencies
- Backup configuration and secrets
- Performance testing and optimization

## Scaling Considerations

### Database

- Enable connection pooling for high traffic
- Consider read replicas for analytics
- Implement partitioning for wealth_history
- Archive old data periodically

### Edge Functions

- Monitor cold start times
- Implement caching for Moralis API calls
- Consider batch processing for multiple wallets
- Set up CDN for static assets

### Real-time

- Monitor concurrent connection limits
- Implement reconnection logic in app
- Consider message queuing for high volume
- Load test real-time subscriptions

## Cost Optimization

### Supabase

- Monitor database size and optimize storage
- Review Edge Function invocation count
- Optimize Realtime connection usage
- Use appropriate instance size

### Moralis

- Monitor API call usage
- Optimize webhook payload size
- Consider caching frequently accessed data
- Review stream configuration efficiency

## Support & Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Moralis Streams Documentation](https://docs.moralis.io/streams-api)
- [Flutter BLoC Documentation](https://bloclibrary.dev)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)

## Version History

- **v1.0.0** (2026-01-20): Initial release with crypto support via Moralis
- **v1.1.0** (TBD): Plaid integration for bank accounts
- **v2.0.0** (TBD): Multi-currency support and advanced analytics

## License

This project is part of the Financo application. All rights reserved.
