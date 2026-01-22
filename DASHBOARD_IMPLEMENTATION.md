# Dashboard Implementation Guide

## Overview

This document describes the complete implementation of the Financo Dashboard with real-time financial data integration, crypto wallet management via Moralis, and bank account integration via Plaid.

## Architecture

The implementation follows **Clean Architecture** principles with three distinct layers:

### 1. Domain Layer (`lib/features/finance/domain/`)

#### Entities
- **Asset**: Represents a single financial asset (crypto wallet, bank account, stock)
  - Added `AssetGroup` enum: `crypto`, `stocks`, `cash`
  - Fields: id, userId, name, type, assetGroup, provider, balanceUsd, etc.

- **GlobalWealth**: Aggregates all user assets
  - Methods: `totalCryptoBalance`, `totalStocksBalance`, `totalCashBalance`
  - Percentages: `cryptoPercentage`, `stocksPercentage`, `cashPercentage`
  - Asset counts: `cryptoAssetCount`, `stocksAssetCount`, `cashAssetCount`

- **WealthSnapshot**: Historical wealth data point for charts

#### Use Cases
- `GetGlobalWealthUseCase`: Fetch aggregated wealth data
- `GetAssetsUseCase`: Fetch all user assets
- `WatchAssetsUseCase`: Stream real-time asset updates
- `AddAssetUseCase`: Add new asset (crypto or bank)
- `DeleteAssetUseCase`: Remove asset
- `SyncAssetsUseCase`: Manually sync asset balances

### 2. Data Layer (`lib/features/finance/data/`)

#### Models
- **AssetModel**: Extends Asset entity with JSON serialization
  - `fromJson()`: Parse Supabase response
  - `toJson()`: Serialize for database operations
  - Includes asset_group parsing

#### Data Sources
- **FinanceRemoteDataSource**: Handles Supabase operations
  - Real-time subscriptions via `watchAssets()`
  - CRUD operations for assets
  - Moralis stream management
  - Plaid integration

#### Repository Implementation
- **FinanceRepositoryImpl**: Implements domain repository interface
  - Error handling with `Either<Failure, Success>`
  - Automatic Moralis stream registration for crypto wallets
  - Data transformation between models and entities

### 3. Presentation Layer (`lib/features/finance/presentation/`)

#### BLoC (Business Logic Component)
- **FinanceBloc**: Manages state and business logic
  - Events: LoadGlobalWealth, WatchAssets, AddAsset, DeleteAsset, SyncAssets
  - States: FinanceInitial, FinanceLoading, GlobalWealthLoaded, AssetAdded, AssetsRealTimeUpdated, FinanceError
  - Real-time subscription management

#### Pages
- **DashboardPage**: Main dashboard with tabs
  - Tab 1: Assets Overview (circular arcs + cards)
  - Tab 2: Breakdown (textual breakdown)
  
- **AddCryptoWalletPage**: Form for adding crypto wallets
  - Wallet address validation (0x... format)
  - Automatic Moralis stream registration
  - Supported chains: Ethereum, Polygon, BSC, Avalanche, Arbitrum, Optimism, Base

- **AddBankAccountPage**: Form for adding bank accounts
  - Plaid Link integration
  - Bank-level security
  - Multiple account types support

#### Widgets
- **CircularWealthIndicator**: Animated circular arcs
  - Three arc segments proportional to asset group percentages
  - Animated net worth display in center
  - Smooth transitions on data updates

- **AssetGroupCard**: Card displaying group summary
  - Icon, title, amount, percentage, asset count
  - Consistent colors across app

- **BreakdownTab**: Detailed textual breakdown
  - Group-by-group breakdown
  - Total summary card

- **AddAssetModal**: Bottom sheet for choosing asset type
  - Crypto Wallet option → AddCryptoWalletPage
  - Bank Account option → AddBankAccountPage
  - Stocks & ETFs option (coming soon)

## Database Schema

### Migration: `20260121_add_asset_group.sql`

```sql
-- Add asset_group enum
CREATE TYPE asset_group AS ENUM ('crypto', 'stocks', 'cash');

-- Add column to assets table
ALTER TABLE assets 
ADD COLUMN asset_group asset_group NOT NULL DEFAULT 'crypto';

-- Migrate existing data
UPDATE assets 
SET asset_group = CASE 
    WHEN type = 'crypto' THEN 'crypto'::asset_group
    WHEN type = 'bank' THEN 'cash'::asset_group
    ELSE 'cash'::asset_group
END;

-- Add index
CREATE INDEX IF NOT EXISTS idx_assets_asset_group ON assets(asset_group);
```

## UI/UX Implementation

### Dashboard Home (Assets Overview Tab)

#### Circular Wealth Indicator
- **Center**: Animated net worth value
  - Format: $XXX.XXK/M/B
  - Animation: 1.5s ease-out cubic curve
  - Updates smoothly on data changes

- **Arc Segments**: Three colored arcs
  - **Crypto**: Primary gradient (purple/blue)
  - **Stocks & ETFs**: Accent gradient (orange)
  - **Cash & Banks**: AccentS gradient (green)
  - Arc size proportional to percentage
  - Small gaps between arcs for visual separation

#### Asset Group Cards
Three cards below the circular indicator:

1. **Crypto Card**
   - Icon: Bitcoin symbol
   - Color: Primary (purple/blue)
   - Shows: Total value, percentage, asset count

2. **Stocks & ETFs Card**
   - Icon: Trending up
   - Color: Accent (orange)
   - Shows: Total value, percentage, asset count

3. **Cash & Banks Card**
   - Icon: Account balance
   - Color: AccentS (green)
   - Shows: Total value, percentage, asset count

### Breakdown Tab

Detailed textual breakdown with:
- Group name and icon
- Total amount (large, colored)
- Percentage badge
- Asset count
- Total summary card at bottom

### Add Asset Flow

1. User taps central FAB (Floating Action Button)
2. AddAssetModal appears from bottom
3. User chooses asset type:
   - **Crypto Wallet** → AddCryptoWalletPage
   - **Bank Account** → AddBankAccountPage
4. User fills form and submits
5. BLoC handles asset creation
6. Real-time update triggers UI refresh
7. Success message shown
8. User returns to dashboard

## Real-Time Data Flow

### Crypto Assets (Moralis)

1. **User adds wallet address**
   - Flutter app calls `AddAssetUseCase`
   - Repository creates asset in Supabase
   - Repository calls Moralis stream manager Edge Function
   - Edge Function adds address to global Moralis stream

2. **Blockchain activity detected**
   - Moralis detects transaction on monitored address
   - Moralis sends webhook to `finance-webhook` Edge Function
   - Edge Function validates webhook signature
   - Edge Function fetches updated networth from Moralis API
   - Edge Function updates asset balance in Supabase

3. **UI updates automatically**
   - Supabase Realtime broadcasts change
   - Flutter app receives update via `WatchAssetsUseCase`
   - BLoC emits `AssetsRealTimeUpdated` state
   - UI rebuilds with new data
   - **No pull-to-refresh needed!**

### Bank Assets (Plaid)

1. **User connects bank account**
   - Flutter app opens Plaid Link
   - User authenticates with bank
   - Plaid returns access token
   - Flutter app calls Plaid Edge Function
   - Edge Function exchanges token and creates asset

2. **Balance updates**
   - Plaid webhook notifies of balance change
   - Edge Function fetches updated balance
   - Edge Function updates asset in Supabase
   - Supabase Realtime broadcasts change
   - Flutter UI updates automatically

## Color Scheme

Consistent colors across the entire dashboard:

- **Crypto**: `AppColors.primary` (purple/blue gradient)
- **Stocks & ETFs**: `AppColors.accent` (orange gradient)
- **Cash & Banks**: `AppColors.accentS` (green gradient)
- **Background**: `AppColors.background` (dark)
- **Cards**: `AppColors.card` (dark gray)
- **Text Primary**: `AppColors.white`
- **Text Secondary**: `AppColors.gray40`

## Typography

Using `AppTypography` for consistency:

- **Headlines**: `headline4Bold`, `headline5Bold`, `headline6Bold`
- **Body**: `headline2Regular`, `headline3Regular`
- **Labels**: `headline1Regular`, `headline1SemiBold`

## Navigation

### AppShellPage Structure

```
AppShellPage
├── AppBar (with user profile menu)
├── Body (TabView)
│   ├── Dashboard (index 0)
│   ├── Transactions (index 1)
│   ├── Analytics (index 2)
│   └── Settings (index 3)
├── FAB (Floating Action Button)
│   └── Opens AddAssetModal
└── BottomAppBar
    ├── Dashboard
    ├── Transactions
    ├── [FAB notch]
    ├── Analytics
    └── Settings
```

## State Management

### BLoC Pattern

```dart
// Load initial data
context.read<FinanceBloc>().add(LoadGlobalWealthEvent());

// Start watching for real-time updates
context.read<FinanceBloc>().add(WatchAssetsEvent());

// Add new asset
context.read<FinanceBloc>().add(AddAssetEvent(
  name: 'My Wallet',
  type: AssetType.crypto,
  assetGroup: AssetGroup.crypto,
  provider: AssetProvider.moralis,
  assetAddressOrId: '0x...',
  initialBalance: 0.0,
));

// Listen to state changes
BlocBuilder<FinanceBloc, FinanceState>(
  builder: (context, state) {
    if (state is GlobalWealthLoaded) {
      return DashboardContent(wealth: state.globalWealth);
    }
    // ...
  },
)
```

## Error Handling

### Domain Layer
- Uses `Either<Failure, Success>` from Dartz
- `ServerFailure`: API/network errors
- `CacheFailure`: Local storage errors

### Presentation Layer
- `FinanceError` state with error message
- User-friendly error messages
- Snackbar notifications for errors

### UI States
- **Loading**: CircularProgressIndicator
- **Error**: Error icon + message + retry option
- **Empty**: Empty state with call-to-action
- **Success**: Data display

## Testing Recommendations

### Unit Tests
- Test use cases with mock repositories
- Test entity calculations (percentages, totals)
- Test BLoC events and state transitions

### Widget Tests
- Test CircularWealthIndicator rendering
- Test AssetGroupCard display
- Test form validation

### Integration Tests
- Test complete add asset flow
- Test real-time updates
- Test navigation

## Deployment Checklist

### Database
- [ ] Run migration: `supabase db push`
- [ ] Verify asset_group column exists
- [ ] Check RLS policies

### Edge Functions
- [ ] Deploy finance-webhook: `supabase functions deploy finance-webhook`
- [ ] Deploy moralis-stream-manager: `supabase functions deploy moralis-stream-manager`
- [ ] Set secrets: `MORALIS_API_KEY`, `PLAID_SECRET`

### Moralis Setup
- [ ] Create Moralis account
- [ ] Get API key
- [ ] Configure webhook URL: `https://[PROJECT_REF].supabase.co/functions/v1/finance-webhook`
- [ ] Test webhook with Moralis dashboard

### Plaid Setup
- [ ] Create Plaid account
- [ ] Get client ID and secret
- [ ] Configure webhook URL
- [ ] Test Link flow

### Flutter App
- [ ] Update dependencies in pubspec.yaml
- [ ] Run dependency injection setup
- [ ] Test on iOS and Android
- [ ] Verify real-time updates work

## Known Limitations

1. **Plaid Link SDK**: Requires native platform setup (not fully implemented in this version)
2. **Stocks & ETFs**: Coming soon - placeholder in UI
3. **Historical Charts**: wealth_history table ready but chart widget not implemented
4. **Multi-currency**: Currently USD only

## Future Enhancements

1. **Historical Performance Charts**: Line chart showing net worth over time
2. **Asset Details Page**: Tap asset card to see transaction history
3. **Budget Tracking**: Set budgets per asset group
4. **Notifications**: Push notifications for large transactions
5. **Export Data**: CSV/PDF export of portfolio
6. **Multi-currency Support**: Support for EUR, GBP, etc.
7. **Tax Reports**: Generate tax documents
8. **AI Insights**: Financial advice based on portfolio

## Support

For issues or questions:
- Check DEPLOYMENT_GUIDE.md for setup instructions
- Check lib/features/finance/README.md for feature documentation
- Review BLoC events and states for integration
- Check Supabase logs for backend issues

---

**Implementation Date**: January 21, 2026  
**Version**: 1.0.0  
**Branch**: feature/finance-realtime-engine
