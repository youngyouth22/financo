# Quick Start Guide - Financo Dashboard

## Prerequisites

- Flutter SDK installed
- Supabase CLI installed
- Moralis account with API key
- Plaid account (optional for bank integration)

## 1. Database Setup

### Apply Migrations

```bash
# Navigate to project directory
cd financo

# Push database migrations to Supabase
supabase db push

# Verify tables exist
supabase db diff
```

### Verify Tables

Check that these tables exist:
- `assets` (with `asset_group` column)
- `wealth_history`

## 2. Edge Functions Deployment

### Deploy Functions

```bash
# Deploy finance webhook
supabase functions deploy finance-webhook

# Deploy Moralis stream manager
supabase functions deploy moralis-stream-manager
```

### Set Secrets

```bash
# Set Moralis API key
supabase secrets set MORALIS_API_KEY=your_moralis_api_key_here

# Set Plaid secret (optional)
supabase secrets set PLAID_SECRET=your_plaid_secret_here
```

### Get Webhook URL

Your webhook URL will be:
```
https://[YOUR_PROJECT_REF].supabase.co/functions/v1/finance-webhook
```

## 3. Moralis Configuration

### Create Stream

1. Go to Moralis Dashboard: https://admin.moralis.io
2. Navigate to Streams
3. Create new stream or use the API:

```bash
# Call the stream manager to setup
curl -X POST https://[YOUR_PROJECT_REF].supabase.co/functions/v1/moralis-stream-manager \
  -H "Content-Type: application/json" \
  -d '{"action": "setup"}'
```

### Configure Webhook

In Moralis Dashboard:
1. Set webhook URL to your Edge Function URL
2. Enable webhook signature verification
3. Select chains to monitor (Ethereum, Polygon, BSC, etc.)

## 4. Flutter App Setup

### Install Dependencies

```bash
# Get Flutter dependencies
flutter pub get

# Run code generation (if needed)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Update Supabase Configuration

Make sure your Supabase URL and Anon Key are set in:
- `lib/core/config/supabase_config.dart`
- Or environment variables

### Run the App

```bash
# Run on connected device/emulator
flutter run

# Or for specific platform
flutter run -d chrome  # Web
flutter run -d ios     # iOS
flutter run -d android # Android
```

## 5. Testing the Dashboard

### Add a Test Crypto Wallet

1. Launch the app and sign in
2. Tap the central **+** button (FAB)
3. Select **"Crypto Wallet"**
4. Enter:
   - **Name**: "My Test Wallet"
   - **Address**: Your Ethereum wallet address (0x...)
5. Tap **"Add Wallet"**

### Verify Real-Time Updates

1. Send a small transaction to your wallet address
2. Wait for blockchain confirmation (~15 seconds)
3. Dashboard should update automatically without refresh
4. Check the circular arcs and cards update

### Add a Test Bank Account (Simulation)

1. Tap the central **+** button
2. Select **"Bank Account"**
3. Tap **"Simulate Connection"** (since Plaid SDK requires native setup)
4. A test bank account will be added

## 6. Verify Dashboard Features

### Assets Overview Tab

✅ Circular wealth indicator displays
✅ Net worth animates on load
✅ Three arc segments show proportions
✅ Three cards display group totals
✅ Percentages match arc sizes

### Breakdown Tab

✅ Textual breakdown displays
✅ Each group shows amount, percentage, count
✅ Total summary card at bottom

### Real-Time Updates

✅ New assets appear automatically
✅ Balance updates without refresh
✅ UI animations smooth

## 7. Common Issues

### Issue: "User not authenticated"

**Solution**: Make sure you're signed in. Check `AuthBloc` state.

### Issue: "Failed to load assets"

**Solution**: 
- Check Supabase connection
- Verify RLS policies allow user to read their assets
- Check browser console for errors

### Issue: "Moralis webhook not working"

**Solution**:
- Verify webhook URL is correct
- Check Edge Function logs: `supabase functions logs finance-webhook`
- Test webhook manually with Moralis dashboard

### Issue: "Asset not added to stream"

**Solution**:
- Check `moralis-stream-manager` Edge Function logs
- Verify `MORALIS_API_KEY` secret is set
- Ensure stream exists (call setup action)

### Issue: "UI not updating in real-time"

**Solution**:
- Check that `WatchAssetsEvent` is dispatched
- Verify Supabase Realtime is enabled on `assets` table
- Check BLoC subscription is active

## 8. Development Tips

### Hot Reload

Flutter supports hot reload for UI changes:
```bash
# Press 'r' in terminal to hot reload
# Press 'R' to hot restart
```

### Debug BLoC

Add debug prints in `FinanceBloc`:
```dart
@override
void onEvent(FinanceEvent event) {
  super.onEvent(event);
  print('FinanceEvent: $event');
}

@override
void onTransition(Transition<FinanceEvent, FinanceState> transition) {
  super.onTransition(transition);
  print('FinanceTransition: $transition');
}
```

### Check Supabase Logs

```bash
# View Edge Function logs
supabase functions logs finance-webhook --tail

# View database logs
supabase db logs --tail
```

### Inspect Realtime

In browser console:
```javascript
// Check Realtime connection
supabase.realtime.channels
```

## 9. Next Steps

### Customize Colors

Edit `lib/common/app_colors.dart` to match your brand:
```dart
static const primary = Color(0xFF6C5CE7);  // Your primary color
static const accent = Color(0xFFFF7675);   // Your accent color
static const accentS = Color(0xFF00B894);  // Your secondary accent
```

### Add More Asset Types

1. Update `AssetGroup` enum in `asset.dart`
2. Add new provider in `AssetProvider` enum
3. Create form page for new asset type
4. Add option in `AddAssetModal`

### Implement Historical Charts

Use `wealth_history` table with a chart library:
```dart
// Example with fl_chart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: wealthHistory.map((w) => 
          FlSpot(w.timestamp.millisecondsSinceEpoch.toDouble(), w.totalAmount)
        ).toList(),
      ),
    ],
  ),
)
```

## 10. Production Deployment

### Checklist

- [ ] Update Supabase project to production tier
- [ ] Enable database backups
- [ ] Set up monitoring and alerts
- [ ] Configure rate limiting on Edge Functions
- [ ] Add error tracking (Sentry, Firebase Crashlytics)
- [ ] Test on multiple devices and screen sizes
- [ ] Implement proper error handling
- [ ] Add loading skeletons for better UX
- [ ] Optimize images and assets
- [ ] Enable code obfuscation for release builds

### Build Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Support

For detailed implementation information, see:
- `DASHBOARD_IMPLEMENTATION.md` - Complete architecture guide
- `DEPLOYMENT_GUIDE.md` - Deployment instructions
- `lib/features/finance/README.md` - Feature documentation

---

**Happy Coding! 🚀**
