# Asset Detail Pages - Premium Fintech UI

## Overview

This module contains 4 specialized detail pages for different asset types in the Financo app. Each page follows a premium fintech design pattern with dark mode (#0F1116) and accent color (#3861FB).

## Pages

### 1. Crypto Wallet Detail Page

**File**: `presentation/pages/crypto_wallet_detail_page.dart`

**Features**:
- Wallet address with copy-to-clipboard functionality
- Total value and 24h change indicator
- Interactive line chart with timeframe selector (1H, 1D, 7D, 30D, 1Y, ALL)
- **Two tabs**:
  - **Assets Tab**: Grid of all tokens with icons, balances, and values
  - **Activity Tab**: Decoded transaction feed (Sent, Received, Swaps, Stake, Unstake) with entity logos

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => CryptoWalletDetailPage(
      walletDetail: cryptoWalletDetail,
    ),
  ),
);
```

---

### 2. Stock & Commodity Detail Page

**File**: `presentation/pages/stock_detail_page.dart`

**Features**:
- Stock symbol and company name
- Current price with 24h change
- Holdings quantity display
- Interactive line chart with timeframe selector
- **Market Statistics Grid**:
  - Market Cap
  - P/E Ratio
  - 52-week High/Low
  - Volume
  - Dividend Yield
- **Diversification Info**:
  - Sector badge
  - Industry badge
  - Country badge with flag emoji
- **Expandable Description**: "About" section with company history

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => StockDetailPage(
      stockDetail: stockDetail,
    ),
  ),
);
```

---

### 3. Bank Account Detail Page

**File**: `presentation/pages/bank_account_detail_page.dart`

**Features**:
- Institution name and account mask (e.g., "**** 4242")
- Account type and subtype display
- Current balance with balance history chart
- **Credit Card Logic**:
  - Credit limit and available balance
  - Credit utilization bar with color coding (green < 30%, yellow < 70%, red >= 70%)
  - Credit used calculation
- **Transaction List**: Recent bank transactions with:
  - Merchant name
  - Category
  - Date
  - Amount (color-coded for debit/credit)
  - Pending status indicator

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BankAccountDetailPage(
      accountDetail: bankAccountDetail,
    ),
  ),
);
```

---

### 4. Manual Asset Detail Page

**File**: `presentation/pages/manual_asset_detail_page.dart`

**Features**:
- Category badge with color coding (Real Estate, Private Equity, Commodity, Collectible, Loan)
- Current value with total gain/loss
- Value history chart
- **Re-evaluate Asset Button**: Manual price update dialog
- **Asset Metadata**:
  - Purchase price and date
  - Category-specific details (property address, loan terms, commodity purity, etc.)
- **Amortization Engine** (Josh's Priority):
  - "Upcoming Recalls / Amortization" section
  - Timeline of next 5 payments
  - Payment breakdown (Principal, Interest, Total)
  - Days until due / overdue indicator
  - Color-coded for overdue payments

**Usage**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ManualAssetDetailPage(
      assetDetail: manualAssetDetail,
    ),
  ),
);
```

---

## Domain Entities

All detail pages use dedicated domain entities:

- `CryptoWalletDetail` - Wallet info, tokens, transactions
- `StockDetail` - Stock info, market stats, diversification
- `BankAccountDetail` - Account info, transactions, credit card data
- `ManualAssetDetail` - Asset info, metadata, amortization schedule

**Location**: `lib/features/finance/domain/entities/`

---

## Shared Components

### PriceLineChart

**File**: `lib/common/common_widgets/price_line_chart.dart`

A reusable line chart component with:
- Gradient fill under the line
- Interactive touch tooltips
- Timeframe selector (1H, 1D, 7D, 30D, 1Y, ALL)
- Color coding for positive/negative trends
- Smooth curved lines using `fl_chart`

**Usage**:
```dart
PriceLineChart(
  priceHistory: [100, 105, 103, 108, 110],
  isPositive: true,
  height: 200,
  showTimeframeSelector: true,
)
```

---

## Design System

### Colors
- Background: `#0F1116` (AppColors.background)
- Accent: `#3861FB` (AppColors.accent)
- Success: Green for positive changes
- Error: Red for negative changes
- Gray scales for borders and secondary text

### Typography
- Uses Inter font family
- Consistent sizing: 36px for main values, 24px for titles, 14px for body text

### Icons
- Material Icons for standard UI elements
- Country flags using `country_picker` package
- Custom entity logos for transactions

---

## Navigation Integration

To integrate with the asset list, modify the asset card tap handler:

```dart
onTap: () {
  if (asset.provider == AssetProvider.moralis) {
    // Navigate to Crypto Wallet Detail
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => CryptoWalletDetailPage(walletDetail: ...),
    ));
  } else if (asset.provider == AssetProvider.fmp) {
    // Navigate to Stock Detail
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => StockDetailPage(stockDetail: ...),
    ));
  } else if (asset.provider == AssetProvider.plaid) {
    // Navigate to Bank Account Detail
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => BankAccountDetailPage(accountDetail: ...),
    ));
  } else if (asset.provider == AssetProvider.manual) {
    // Navigate to Manual Asset Detail
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ManualAssetDetailPage(assetDetail: ...),
    ));
  }
}
```

---

## Dependencies

All required packages are already in `pubspec.yaml`:
- `fl_chart: ^1.1.1` - For line charts
- `country_picker: ^2.0.26` - For country flags
- `intl: ^0.20.2` - For number and date formatting
- `rrule: ^0.2.15` - For amortization recurrence rules

---

## Next Steps

1. **Create Use Cases**: Implement use cases to fetch detailed data for each asset type
2. **Create Repositories**: Add repository methods to fetch data from Supabase/APIs
3. **Create BLoCs**: Implement BLoCs for state management
4. **Wire Navigation**: Connect asset cards to detail pages
5. **Test with Real Data**: Integrate with Moralis, FMP, and Plaid APIs

---

## Notes

- All pages handle loading and error states
- Responsive design for different screen sizes
- Smooth animations and transitions
- Production-ready code with proper error handling
- Clean Architecture principles followed
