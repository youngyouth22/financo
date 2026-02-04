# Asset Payouts & Amortization Tracking System

## Overview

This implementation adds a complete asset payouts tracking system to Financo, enabling users to:
- Track payments received from manual assets (loans, real estate, bonds, etc.)
- View payment history and remaining balances
- Receive automated FCM push notifications for upcoming payments
- Mark reminders as received directly from the app

---

## 🎯 Features Implemented

### 1. **Database Schema** (Supabase)

#### New Table: `asset_payouts`
Stores history of actual payments received from manual assets.

**Columns:**
- `id` (UUID, primary key)
- `user_id` (UUID, references profiles)
- `asset_id` (UUID, references assets)
- `amount` (numeric)
- `payout_date` (timestamp)
- `notes` (text, optional)
- `created_at` (timestamp)
- `updated_at` (timestamp)

**Indexes:**
- `idx_asset_payouts_user_id`
- `idx_asset_payouts_asset_id`
- `idx_asset_payouts_payout_date`
- `idx_asset_payouts_user_asset`

**RLS Policies:**
- Users can only view/insert/update/delete their own payouts

#### FCM Support
- Added `fcm_token` column to `profiles` table
- Index on `fcm_token` for fast lookups

#### Helper Functions
1. **`get_asset_payout_summary(p_asset_id UUID)`**
   - Returns total expected, total received, remaining balance, payout count, last payout date

2. **`update_reminder_next_event_date(p_reminder_id UUID, p_rrule_expression TEXT)`**
   - Calculates and updates next event date based on RRULE expression

#### Cron Job
- Daily job at 08:00 AM UTC to trigger `send-asset-reminders` Edge Function
- Uses `pg_cron` extension

---

### 2. **Edge Function: send-asset-reminders**

**Purpose:** Send FCM push notifications for reminders due today

**Flow:**
1. Fetch all reminders where `next_event_date` is today
2. Get user's `fcm_token` from profiles
3. Send FCM notification via Firebase Cloud Messaging API
4. Log success/failure for each notification

**Environment Variables Required:**
- `FIREBASE_SERVICE_ACCOUNT` - Firebase service account JSON (stored in Supabase Secrets)

**Notification Format:**
```json
{
  "title": "💰 {reminder_title}",
  "body": "Expected payment: ${amount} from {asset_name}",
  "data": {
    "type": "asset_reminder",
    "asset_id": "...",
    "reminder_id": "...",
    "amount": "..."
  }
}
```

---

### 3. **Flutter Implementation**

#### Domain Layer

**Entities:**
- `AssetPayout` - Represents a single payout record
- `AssetPayoutSummary` - Summary stats (total expected, received, remaining)

**Use Cases:**
- `GetAssetPayoutSummaryUseCase` - Fetch payout summary for an asset
- `GetAssetPayoutsUseCase` - Fetch all payouts for an asset
- `MarkReminderAsReceivedUseCase` - Mark reminder as received (creates payout + updates next event date)

#### Data Layer

**Models:**
- `AssetPayoutModel` - JSON serialization for AssetPayout
- `AssetPayoutSummaryModel` - JSON serialization for AssetPayoutSummary

**Repository Methods:**
```dart
Future<Either<Failure, AssetPayoutSummary>> getAssetPayoutSummary(String assetId);
Future<Either<Failure, List<AssetPayout>>> getAssetPayouts(String assetId);
Future<Either<Failure, void>> markReminderAsReceived({
  required String reminderId,
  required String assetId,
  required double amount,
  required DateTime payoutDate,
  String? notes,
});
```

**DataSource Implementation:**
- `getAssetPayoutSummary()` - Calls `get_asset_payout_summary` RPC
- `getAssetPayouts()` - Queries `asset_payouts` table
- `markReminderAsReceived()` - Creates payout + calls `update_reminder_next_event_date` RPC

#### Presentation Layer

**BLoC: ManualAssetDetailBloc**

**Events:**
- `LoadAssetDetailEvent` - Load summary + payouts
- `MarkReminderReceivedEvent` - Mark reminder as received
- `RefreshAssetDetailEvent` - Refresh data

**States:**
- `ManualAssetDetailInitial`
- `ManualAssetDetailLoading`
- `ManualAssetDetailLoaded` - Contains summary + payouts
- `ManualAssetDetailError`
- `MarkingReminderReceived`
- `ReminderMarkedSuccess`

**UI: ManualAssetDetailPage (Upgraded)**

**Header Stats Section:**
```
┌─────────────┬─────────────┬─────────────┐
│ Total       │ Total       │ Remaining   │
│ Expected    │ Received    │ Balance     │
│ $10,000     │ $3,000      │ $7,000      │
└─────────────┴─────────────┴─────────────┘
```

**Tabbed View:**
1. **Schedule Tab**
   - Shows upcoming reminders
   - "Mark as Received" button for each reminder
   - TODO: Fetch reminders from database

2. **History Tab**
   - Chronological list of past payouts
   - Shows date, amount, and notes
   - Empty state if no history

---

## 📁 Files Created/Modified

### Created Files

**Database:**
- `supabase/migrations/20260204_asset_payouts_and_fcm.sql`
- `supabase/functions/send-asset-reminders/index.ts`

**Domain:**
- `lib/features/finance/domain/entities/asset_payout.dart`
- `lib/features/finance/domain/usecases/payout_usecases/get_asset_payout_summary_usecase.dart`
- `lib/features/finance/domain/usecases/payout_usecases/get_asset_payouts_usecase.dart`
- `lib/features/finance/domain/usecases/payout_usecases/mark_reminder_as_received_usecase.dart`

**Data:**
- `lib/features/finance/data/models/asset_payout_model.dart`

**Presentation:**
- `lib/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_bloc.dart`
- `lib/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_event.dart`
- `lib/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_state.dart`

### Modified Files

**Domain:**
- `lib/features/finance/domain/repositories/finance_repository.dart` - Added payout methods

**Data:**
- `lib/features/finance/data/repositories/finance_repository_impl.dart` - Implemented payout methods
- `lib/features/finance/data/datasources/finance_remote_datasource.dart` - Added payout datasource methods

**Presentation:**
- `lib/features/asset_details/presentation/pages/manual_asset_detail_page.dart` - Completely rewritten with tabs
- `lib/features/asset_details/presentation/utils/asset_detail_navigator.dart` - Added ManualAssetDetailBloc provider

**DI:**
- `lib/di/injection_container.dart` - Registered payout use cases and ManualAssetDetailBloc

---

## 🚀 Setup Instructions

### 1. Run Database Migration

```bash
# Apply migration via Supabase Dashboard or CLI
supabase db push
```

### 2. Deploy Edge Function

```bash
# Deploy send-asset-reminders function
supabase functions deploy send-asset-reminders
```

### 3. Set Firebase Credentials

```bash
# Add Firebase service account to Supabase Secrets
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
```

### 4. Enable pg_cron (Manual via Dashboard)

```sql
-- Run this in Supabase SQL Editor (requires superuser)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule daily reminder check
SELECT cron.schedule(
  'send-daily-asset-reminders',
  '0 8 * * *',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-asset-reminders',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
    ),
    body := jsonb_build_object('trigger', 'cron')
  ) AS request_id;
  $$
);
```

### 5. Flutter Dependencies

No new dependencies required! All features use existing packages.

---

## 🧪 Testing

### Test Database Functions

```sql
-- Test payout summary
SELECT * FROM get_asset_payout_summary('YOUR_ASSET_ID');

-- Test update next event date
SELECT update_reminder_next_event_date('YOUR_REMINDER_ID', 'FREQ=MONTHLY;INTERVAL=1');
```

### Test Edge Function

```bash
# Invoke manually
curl -X POST https://YOUR_PROJECT_ID.supabase.co/functions/v1/send-asset-reminders \
  -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"trigger":"manual"}'
```

### Test Flutter UI

1. Create a manual asset
2. Add a reminder for the asset
3. Navigate to asset detail page
4. Verify header stats display correctly
5. Switch to History tab
6. Mark a reminder as received (TODO: implement Schedule tab first)
7. Verify payout appears in History tab
8. Verify summary stats update

---

## 📊 Data Flow

### Mark Reminder as Received Flow

```
User taps "Mark as Received"
    ↓
MarkReminderReceivedEvent dispatched
    ↓
ManualAssetDetailBloc receives event
    ↓
MarkReminderAsReceivedUseCase called
    ↓
Repository.markReminderAsReceived()
    ↓
DataSource.markReminderAsReceived()
    ↓
1. INSERT into asset_payouts
2. SELECT reminder details
3. CALL update_reminder_next_event_date()
    ↓
Success → ReminderMarkedSuccess state
    ↓
LoadAssetDetailEvent auto-dispatched
    ↓
UI refreshes with updated data
```

---

## 🎨 UI Design

### Colors (Fintech Premium Theme)
- Background: `#0F1116`
- Card Background: `#1A1D24`
- Primary: `#3861FB`
- Accent: `#6366F1`
- Success: `#10B981`
- Warning: `#F59E0B`
- Error: `#EF4444`

### Typography
- H3: 24px, Bold
- Body: 14px, Regular
- Caption: 12px, Regular

---

## 🔮 Future Enhancements

### Schedule Tab (TODO)
- Fetch reminders from `asset_reminders` table
- Display upcoming reminders with dates
- "Mark as Received" button for each reminder
- Calculate future occurrences from RRULE

### Notifications
- Handle FCM token registration in Flutter
- Listen for FCM messages in app
- Navigate to asset detail when notification tapped

### Analytics
- Track payout completion rate
- Average time between reminders
- Total income from manual assets

---

## 🐛 Known Issues

1. **Schedule Tab** - Currently shows placeholder, needs reminder fetching logic
2. **RRULE Parsing** - Simplified implementation in database function, may need full RRULE parser for complex patterns
3. **FCM Token** - No Flutter code yet to register/update FCM tokens

---

## 📚 References

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [Firebase Cloud Messaging API](https://firebase.google.com/docs/cloud-messaging/server)
- [RRULE Specification (RFC 5545)](https://datatracker.ietf.org/doc/html/rfc5545)
- [pg_cron Documentation](https://github.com/citusdata/pg_cron)

---

## ✅ Completion Checklist

- [x] Database migration created
- [x] FCM support added to profiles
- [x] Edge Function created
- [x] Cron job configured
- [x] Domain entities created
- [x] Use cases implemented
- [x] Repository methods added
- [x] DataSource methods implemented
- [x] BLoC created
- [x] UI upgraded with tabs
- [x] Header stats implemented
- [x] History tab implemented
- [ ] Schedule tab implemented (TODO)
- [ ] FCM token registration (TODO)
- [ ] FCM message handling (TODO)

---

**Implementation Date:** February 4, 2026  
**Developer:** Manus AI  
**Branch:** `manus`
