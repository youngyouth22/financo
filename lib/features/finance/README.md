# Finance Feature - Real-time Asset Tracking

## Overview

The Finance feature implements a production-ready financial synchronization engine with real-time updates for cryptocurrency and bank account tracking. It follows Clean Architecture principles with clear separation between Domain, Data, and Presentation layers.

## Architecture

```
finance/
├── data/
│   ├── datasources/
│   │   └── finance_remote_datasource.dart
│   ├── models/
│   │   ├── asset_model.dart
│   │   └── wealth_snapshot_model.dart
│   └── repositories/
│       └── finance_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── asset.dart
│   │   ├── wealth_snapshot.dart
│   │   └── global_wealth.dart
│   ├── repositories/
│   │   └── finance_repository.dart
│   └── usecases/
│       ├── get_global_wealth_usecase.dart
│       ├── get_assets_usecase.dart
│       ├── watch_assets_usecase.dart
│       ├── add_asset_usecase.dart
│       ├── delete_asset_usecase.dart
│       ├── get_net_worth_usecase.dart
│       ├── get_wealth_history_usecase.dart
│       └── sync_assets_usecase.dart
└── presentation/
    └── bloc/
        ├── finance_bloc.dart
        ├── finance_event.dart
        └── finance_state.dart
```

## Key Features

### 1. Real-time Asset Synchronization

- **Crypto Assets**: Automatically tracked via Moralis Streams
- **Bank Accounts**: Synced via Plaid API
- **Live Updates**: Supabase Realtime subscriptions for instant UI updates

### 2. Clean Architecture Implementation

- **Domain Layer**: Pure business logic with no external dependencies
- **Data Layer**: Handles API calls, database operations, and data mapping
- **Presentation Layer**: BLoC pattern for state management

### 3. Functional Programming with Dartz

All repository methods return `Either<Failure, Success>` for robust error handling:

```dart
Future<Either<Failure, List<Asset>>> getAssets();
```

### 4. Dependency Injection with Get_it

All dependencies are registered in `injection_container.dart` and resolved automatically.

## Domain Entities

### Asset

Represents a financial asset (crypto wallet or bank account).

**Properties:**
- `id`: Unique identifier
- `userId`: Owner's user ID
- `name`: Display name
- `type`: AssetType (crypto/bank)
- `provider`: AssetProvider (moralis/plaid)
- `balanceUsd`: Current balance in USD
- `assetAddressOrId`: Wallet address or account ID
- `lastSync`: Last synchronization timestamp

**Computed Properties:**
- `isCrypto`: Boolean indicating if asset is crypto
- `isBank`: Boolean indicating if asset is bank account
- `formattedBalance`: USD formatted string
- `isStale`: Boolean indicating if data is older than 24 hours

### GlobalWealth

Aggregates all user assets with calculated metrics.

**Properties:**
- `assets`: List of all assets
- `lastUpdated`: Last update timestamp

**Computed Properties:**
- `netWorth`: Total value across all assets
- `cryptoAssets`: Filtered list of crypto assets
- `bankAssets`: Filtered list of bank assets
- `totalCryptoBalance`: Sum of crypto balances
- `totalBankBalance`: Sum of bank balances
- `cryptoPercentage`: Percentage of wealth in crypto
- `bankPercentage`: Percentage of wealth in bank accounts

### WealthSnapshot

Time-series data point for wealth tracking.

**Properties:**
- `id`: Unique identifier
- `userId`: Owner's user ID
- `totalAmount`: Total wealth at this point
- `timestamp`: When snapshot was recorded

## Use Cases

### GetGlobalWealthUseCase

Retrieves complete financial portfolio with all assets and metrics.

**Usage:**
```dart
final result = await getGlobalWealthUseCase(NoParams());
result.fold(
  (failure) => print('Error: ${failure.message}'),
  (globalWealth) => print('Net Worth: ${globalWealth.formattedNetWorth}'),
);
```

### WatchAssetsUseCase

Streams real-time asset updates from Supabase.

**Usage:**
```dart
watchAssetsUseCase().listen((result) {
  result.fold(
    (failure) => print('Error: ${failure.message}'),
    (assets) => print('Assets updated: ${assets.length}'),
  );
});
```

### AddAssetUseCase

Adds a new asset and automatically registers crypto wallets with Moralis Stream.

**Usage:**
```dart
final params = AddAssetParams(
  name: 'My Ethereum Wallet',
  type: AssetType.crypto,
  provider: AssetProvider.moralis,
  assetAddressOrId: '0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb',
);

final result = await addAssetUseCase(params);
```

### DeleteAssetUseCase

Removes an asset and unregisters from Moralis Stream if crypto.

**Usage:**
```dart
final params = DeleteAssetParams(assetId: 'asset-uuid');
final result = await deleteAssetUseCase(params);
```

### SyncAssetsUseCase

Manually triggers asset synchronization (useful for pull-to-refresh).

**Usage:**
```dart
final result = await syncAssetsUseCase(NoParams());
```

## BLoC Events & States

### Events

- `LoadGlobalWealthEvent`: Load complete portfolio
- `LoadAssetsEvent`: Load all assets
- `WatchAssetsEvent`: Start real-time subscription
- `StopWatchingAssetsEvent`: Stop real-time subscription
- `AssetsUpdatedEvent`: Triggered by real-time updates
- `AddAssetEvent`: Add new asset
- `DeleteAssetEvent`: Remove asset
- `LoadWealthHistoryEvent`: Load historical data
- `SyncAssetsEvent`: Manual sync
- `CalculateNetWorthEvent`: Calculate current net worth

### States

- `FinanceInitial`: Initial state
- `FinanceLoading`: Loading data
- `GlobalWealthLoaded`: Portfolio loaded
- `AssetsLoaded`: Assets loaded
- `AssetsRealTimeUpdated`: Real-time update received
- `WealthHistoryLoaded`: History loaded
- `NetWorthCalculated`: Net worth calculated
- `AssetAdded`: Asset successfully added
- `AssetDeleted`: Asset successfully deleted
- `AssetsSyncing`: Sync in progress
- `AssetsSynced`: Sync complete
- `FinanceError`: Error occurred

## Usage Example

### Basic Setup

```dart
// In your widget
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<FinanceBloc>()
        ..add(const WatchAssetsEvent()), // Start real-time updates
      child: DashboardView(),
    );
  }
}
```

### Listening to Real-time Updates

```dart
class DashboardView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceBloc, FinanceState>(
      builder: (context, state) {
        if (state is FinanceLoading) {
          return CircularProgressIndicator();
        }
        
        if (state is AssetsLoaded) {
          return ListView.builder(
            itemCount: state.assets.length,
            itemBuilder: (context, index) {
              final asset = state.assets[index];
              return ListTile(
                title: Text(asset.name),
                subtitle: Text(asset.formattedBalance),
              );
            },
          );
        }
        
        if (state is AssetsRealTimeUpdated) {
          // UI automatically updates when assets change
          return ListView.builder(
            itemCount: state.assets.length,
            itemBuilder: (context, index) {
              final asset = state.assets[index];
              return ListTile(
                title: Text(asset.name),
                subtitle: Text(asset.formattedBalance),
                trailing: Text('Updated: ${state.updatedAt}'),
              );
            },
          );
        }
        
        if (state is FinanceError) {
          return Text('Error: ${state.message}');
        }
        
        return Container();
      },
    );
  }
}
```

### Adding a Crypto Wallet

```dart
void addWallet(BuildContext context, String address) {
  context.read<FinanceBloc>().add(
    AddAssetEvent(
      name: 'My Wallet',
      type: AssetType.crypto,
      provider: AssetProvider.moralis,
      assetAddressOrId: address,
    ),
  );
}
```

### Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    context.read<FinanceBloc>().add(const SyncAssetsEvent());
    // Wait for sync to complete
    await context.read<FinanceBloc>().stream.firstWhere(
      (state) => state is AssetsSynced || state is FinanceError,
    );
  },
  child: AssetsList(),
);
```

## Data Flow

### Real-time Update Flow

1. User adds crypto wallet via `AddAssetEvent`
2. Asset is stored in Supabase `assets` table
3. Wallet address is registered with Moralis Stream
4. Moralis detects blockchain activity
5. Webhook triggers Supabase Edge Function
6. Edge Function updates `assets` table
7. Supabase Realtime broadcasts change
8. Flutter app receives update via `WatchAssetsUseCase`
9. BLoC emits `AssetsRealTimeUpdated` state
10. UI automatically refreshes

### Manual Sync Flow

1. User triggers pull-to-refresh
2. `SyncAssetsEvent` is dispatched
3. `SyncAssetsUseCase` calls repository
4. Repository invokes `recordWealthSnapshot` RPC
5. Database recalculates net worth
6. Snapshot is recorded in `wealth_history`
7. BLoC emits `AssetsSynced` state
8. Assets are reloaded

## Error Handling

All errors are wrapped in `Failure` objects:

```dart
abstract class Failure extends Equatable {
  final String message;
  const Failure({required this.message});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}
```

Handle errors in UI:

```dart
if (state is FinanceError) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(state.message)),
  );
}
```

## Testing

### Unit Tests

Test use cases:

```dart
test('should return GlobalWealth when repository call succeeds', () async {
  // Arrange
  final globalWealth = GlobalWealth.empty();
  when(mockRepository.getGlobalWealth())
      .thenAnswer((_) async => Right(globalWealth));
  
  // Act
  final result = await useCase(NoParams());
  
  // Assert
  expect(result, Right(globalWealth));
  verify(mockRepository.getGlobalWealth());
});
```

### Integration Tests

Test BLoC:

```dart
blocTest<FinanceBloc, FinanceState>(
  'emits [FinanceLoading, GlobalWealthLoaded] when LoadGlobalWealthEvent is added',
  build: () => FinanceBloc(...),
  act: (bloc) => bloc.add(const LoadGlobalWealthEvent()),
  expect: () => [
    const FinanceLoading(),
    isA<GlobalWealthLoaded>(),
  ],
);
```

## Performance Considerations

1. **Lazy Loading**: Use cases and repositories are lazy singletons
2. **Stream Management**: BLoC automatically cancels subscriptions on close
3. **Efficient Queries**: Database queries use indexes and RLS
4. **Caching**: Consider implementing caching layer for frequently accessed data

## Security

1. **Row Level Security**: All database queries respect RLS policies
2. **Authentication**: User ID is automatically injected from Supabase auth
3. **Webhook Verification**: Moralis webhooks are signature-verified
4. **Service Role**: Edge Functions use service role key, never exposed to client

## Future Enhancements

- [ ] Plaid integration for bank accounts
- [ ] Asset performance analytics
- [ ] Portfolio rebalancing suggestions
- [ ] Multi-currency support
- [ ] Offline support with local caching
- [ ] Export to CSV/PDF
- [ ] Budget tracking
- [ ] Goal setting and tracking

## Dependencies

- `supabase_flutter`: ^2.12.0
- `dartz`: ^0.10.1
- `get_it`: ^8.0.3
- `flutter_bloc`: ^8.1.6
- `equatable`: ^2.0.7

## Related Documentation

- [Supabase Edge Functions](../../../supabase/README.md)
- [Database Schema](../../../supabase/migrations/20260120_create_finance_tables.sql)
- [Clean Architecture Guide](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
