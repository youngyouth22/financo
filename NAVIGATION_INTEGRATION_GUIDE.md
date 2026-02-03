# Asset Detail Navigation Integration Guide

## Overview

This guide explains how to integrate the asset detail navigation system into your `AssetsPage` and `DashboardPage`.

---

## Quick Integration

### 1. Import the Navigator

```dart
import 'package:financo/features/asset_details/presentation/utils/asset_detail_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

### 2. Add Navigation to Asset Cards

In your asset card `onTap` handler, add:

```dart
onTap: () {
  final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
  AssetDetailNavigator.navigateToAssetDetail(
    context,
    asset,  // Your Asset entity
    userId,
  );
}
```

---

## Example: AssetsPage Integration

```dart
// In lib/features/assets/presentation/pages/assets_page.dart

import 'package:financo/features/asset_details/presentation/utils/asset_detail_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Inside your asset list builder:
ListView.builder(
  itemCount: assets.length,
  itemBuilder: (context, index) {
    final asset = assets[index];
    
    return AssetCard(
      asset: asset,
      onTap: () {
        final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
        AssetDetailNavigator.navigateToAssetDetail(
          context,
          asset,
          userId,
        );
      },
    );
  },
)
```

---

## Example: DashboardPage Integration

```dart
// In lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'package:financo/features/asset_details/presentation/utils/asset_detail_navigator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Inside your top assets section:
GestureDetector(
  onTap: () {
    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    AssetDetailNavigator.navigateToAssetDetail(
      context,
      asset,
      userId,
    );
  },
  child: TopAssetTile(asset: asset),
)
```

---

## How It Works

### Automatic Provider Detection

The navigator automatically detects the asset provider and calls the correct Edge Function:

| Provider | Edge Function | Parameters |
|----------|---------------|------------|
| `moralis` | `get-wallet-details` | `address`, `chain` |
| `fmp` | `get-stock-details` | `symbol`, `userId`, `timeframe` |
| `plaid` | `get-bank-details` | `itemId`, `accountId`, `userId` |
| `manual` | `get-manual-asset-details` | `assetId`, `userId` |

### Loading Flow

1. **Shimmer Loading**: Shows `DetailShimmer` widget with premium animation
2. **Edge Function Call**: Fetches data from Supabase Edge Function
3. **Success**: Displays the appropriate detail page
4. **Error**: Shows error view with retry button

---

## State Management

The navigation uses `AssetDetailBloc` with these states:

- `AssetDetailLoading` → Shows shimmer
- `CryptoWalletDetailLoaded` → Shows `CryptoWalletDetailPage`
- `StockDetailLoaded` → Shows `StockDetailPage`
- `BankAccountDetailLoaded` → Shows `BankAccountDetailPage`
- `ManualAssetDetailLoaded` → Shows `ManualAssetDetailPage`
- `AssetDetailError` → Shows error view with retry

---

## Error Handling

Errors are automatically handled with:

- **Network errors**: "No internet connection" message
- **API errors**: Specific error message from Edge Function
- **Retry button**: Automatically retries the last failed request

---

## Metadata Requirements

Ensure your `Asset` entities have the correct metadata:

### Crypto (Moralis)
```dart
metadata: {
  'address': '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb'
}
```

### Bank Account (Plaid)
```dart
metadata: {
  'itemId': 'item_xxx',
  'accountId': 'acc_xxx'
}
```

### Stock (FMP)
No metadata required, uses `symbol` field directly.

### Manual Asset
No metadata required, uses `id` field directly.

---

## Testing

To test the navigation:

1. Run the app: `flutter run`
2. Navigate to Assets page
3. Tap on any asset card
4. Verify:
   - Shimmer animation appears
   - Detail page loads with correct data
   - Chart displays price history
   - All sections render correctly

---

## Troubleshooting

### "No internet connection"
- Check device connectivity
- Verify Supabase Edge Functions are deployed

### "Failed to fetch details"
- Check Edge Function logs in Supabase dashboard
- Verify API keys (MORALIS_API_KEY, FMP_API_KEY, PLAID_SECRET)
- Check user authentication status

### Type errors
- Ensure all entity fields match Edge Function response structure
- Verify metadata contains required fields

---

## Next Steps

After integration, you can:

1. Customize the shimmer animation duration
2. Add analytics tracking for detail page views
3. Implement pull-to-refresh on detail pages
4. Add favorite/bookmark functionality

---

## Support

For issues or questions, check:
- Edge Function logs in Supabase dashboard
- BLoC state transitions in Flutter DevTools
- Network requests in browser/app inspector
