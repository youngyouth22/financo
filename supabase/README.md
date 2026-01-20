# Supabase Edge Functions - Finance Realtime Engine

## Overview

This directory contains Supabase Edge Functions and database migrations for the Finance Realtime Engine, which provides real-time synchronization of crypto assets via Moralis Streams and bank accounts via Plaid.

## Directory Structure

```
supabase/
├── migrations/
│   └── 20260120_create_finance_tables.sql
├── functions/
│   ├── finance-webhook/
│   │   ├── index.ts
│   │   └── deno.json
│   └── moralis-stream-manager/
│       ├── index.ts
│       └── deno.json
└── README.md
```

## Database Schema

### Tables

- **assets**: Stores all user financial assets (crypto wallets and bank accounts)
- **wealth_history**: Time-series data for tracking total wealth over time

### Key Features

- Row Level Security (RLS) enabled
- Realtime subscriptions enabled on `assets` table
- Automatic cascade deletion on user removal
- Helper functions for net worth calculation

## Edge Functions

### 1. finance-webhook

**Purpose**: Handle Moralis Streams webhooks for real-time crypto asset updates

**Endpoint**: `https://[PROJECT_REF].supabase.co/functions/v1/finance-webhook`

**Features**:
- Validates Moralis webhook signatures
- Handles test webhooks
- Processes confirmed transactions only
- Updates asset balances in real-time
- Records wealth history snapshots

**Environment Variables Required**:
- `MORALIS_API_KEY`: Your Moralis API key
- `MORALIS_WEBHOOK_SECRET`: Webhook secret for signature verification
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database access

### 2. moralis-stream-manager

**Purpose**: Manage Moralis Streams (create, add/remove addresses, cleanup)

**Endpoint**: `https://[PROJECT_REF].supabase.co/functions/v1/moralis-stream-manager`

**Actions**:

#### Setup Stream
```json
{
  "action": "setup"
}
```

#### Add Wallet Address
```json
{
  "action": "add_address",
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
}
```

#### Remove Wallet Address
```json
{
  "action": "remove_address",
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb"
}
```

#### Cleanup User Account
```json
{
  "action": "cleanup_user",
  "userId": "uuid-here"
}
```

**Environment Variables Required**:
- `MORALIS_API_KEY`: Your Moralis API key
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Service role key for database access
- `FINANCE_WEBHOOK_URL`: (Optional) Custom webhook URL

## Deployment Instructions

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link to Your Project

```bash
supabase link --project-ref [YOUR_PROJECT_REF]
```

### 4. Run Database Migration

```bash
supabase db push
```

### 5. Deploy Edge Functions

```bash
# Deploy finance-webhook
supabase functions deploy finance-webhook

# Deploy moralis-stream-manager
supabase functions deploy moralis-stream-manager
```

### 6. Set Environment Secrets

```bash
# Set Moralis API key
supabase secrets set MORALIS_API_KEY=your_moralis_api_key

# Set Moralis webhook secret
supabase secrets set MORALIS_WEBHOOK_SECRET=your_webhook_secret

# Set Supabase service role key (if not auto-set)
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

### 7. Configure Moralis Stream

After deployment, call the stream manager to setup:

```bash
curl -X POST https://[PROJECT_REF].supabase.co/functions/v1/moralis-stream-manager \
  -H "Content-Type: application/json" \
  -d '{"action": "setup"}'
```

## Supported Chains

The system monitors the following EVM chains:
- Ethereum (0x1)
- Polygon (0x89)
- BSC (0x38)
- Avalanche (0xa86a)
- Arbitrum (0xa4b1)
- Optimism (0xa)
- Base (0x2105)

## Testing

### Test Webhook Locally

```bash
supabase functions serve finance-webhook
```

Then send a test request:

```bash
curl -X POST http://localhost:54321/functions/v1/finance-webhook \
  -H "Content-Type: application/json" \
  -d '{"test": true}'
```

### Test Stream Manager Locally

```bash
supabase functions serve moralis-stream-manager
```

## Security Considerations

1. **Webhook Signature Verification**: All Moralis webhooks are verified using HMAC-SHA256
2. **Row Level Security**: Database access is restricted by user authentication
3. **Service Role Key**: Used only in Edge Functions, never exposed to client
4. **HTTPS Only**: All webhook endpoints use HTTPS

## Monitoring

Monitor function logs:

```bash
supabase functions logs finance-webhook
supabase functions logs moralis-stream-manager
```

## Troubleshooting

### Webhook Not Receiving Events

1. Verify webhook URL is correct in Moralis dashboard
2. Check function logs for errors
3. Ensure MORALIS_WEBHOOK_SECRET is set correctly

### Address Not Being Tracked

1. Verify address was added to stream successfully
2. Check if address has any transactions on supported chains
3. Review Moralis Stream configuration

### Database Connection Issues

1. Verify SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are set
2. Check RLS policies are correctly configured
3. Ensure service role key has necessary permissions

## Support

For issues or questions, refer to:
- [Supabase Documentation](https://supabase.com/docs)
- [Moralis Streams Documentation](https://docs.moralis.io/streams-api)
