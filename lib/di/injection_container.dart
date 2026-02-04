import 'package:financo/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:financo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';
import 'package:financo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:financo/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:financo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:financo/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:financo/features/finance/domain/repositories/finance_repository.dart';
import 'package:financo/features/finance/domain/usecases/add_asset_reminder_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_crypto_wallet_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_manual_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_stock_usecase.dart';
import 'package:financo/features/finance/domain/usecases/delete_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/exchange_plaid_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_assets_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_daily_change_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_networth_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_plaid_link_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_wealth_history_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_portfolio_insights_usecase.dart';
import 'package:financo/features/finance/domain/usecases/search_stocks_usecase.dart';
import 'package:financo/features/finance/domain/usecases/update_asset_quantity_usecase.dart';
import 'package:financo/features/finance/domain/usecases/watch_assets_usecase.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:financo/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:financo/features/assets/presentation/bloc/assets_bloc.dart';
import 'package:financo/features/insights/presentation/bloc/insights_bloc.dart';
import 'package:financo/features/asset_details/presentation/bloc/asset_detail_bloc.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_crypto_wallet_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_stock_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_bank_account_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/detail_usecases/get_manual_asset_details_usecase.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/get_asset_payout_summary_usecase.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/get_asset_payouts_usecase.dart';
import 'package:financo/features/finance/domain/usecases/payout_usecases/mark_reminder_as_received_usecase.dart';
import 'package:financo/features/finance/presentation/bloc/manual_asset_detail/manual_asset_detail_bloc.dart';
import 'package:financo/core/services/connectivity_service.dart';
import 'package:financo/core/services/security_service.dart';
import 'package:financo/core/services/supabase_error_handler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Instance globale du service locator Get_it.
final sl = GetIt.instance;

/// Initialise toutes les dépendances de l'application.
///
/// Cette fonction doit être appelée au démarrage de l'application,
/// avant le lancement du widget principal.
Future<void> initializeDependencies() async {
  // ============================================================================
  // External Dependencies (Clients externes)
  // ============================================================================

  // Initialize ConnectivityService first to check connection
  final connectivityService = ConnectivityService();
  await connectivityService.initialize();
  sl.registerLazySingleton<ConnectivityService>(() => connectivityService);
  
  // Check if we have connection before initializing Supabase
  final hasConnection = await connectivityService.hasConnection;
  
  // Initialisation de Supabase avec gestion d'erreur de connexion
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
    authOptions: FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Disable auto-refresh when offline to prevent connection errors
      autoRefreshToken: hasConnection,
    ),
    realtimeClientOptions: const RealtimeClientOptions(
      // Disable realtime when offline
      eventsPerSecond: 2,
    ),
  );

  // Enregistrement du client Supabase
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  
  // Initialize SupabaseErrorHandler to catch auth errors
  final errorHandler = SupabaseErrorHandler(
    connectivityService: connectivityService,
  );
  await errorHandler.initialize(Supabase.instance.client);
  sl.registerLazySingleton<SupabaseErrorHandler>(() => errorHandler);

  // Enregistrement de SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // Enregistrement de LocalAuthentication
  sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());

  // Enregistrement du SecurityService
  sl.registerLazySingleton<SecurityService>(
    () => SecurityService(
      prefs: sl<SharedPreferences>(),
      localAuth: sl<LocalAuthentication>(),
    ),
  );

  // ConnectivityService already initialized above

  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  sl.registerLazySingleton<GoogleSignIn>(() => googleSignIn);

  // ============================================================================
  // Features - Authentication
  // ============================================================================

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(supabaseClient: sl(), googleSignIn: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => LoginWithGoogleUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // BLoC
  sl.registerFactory(
    () => AuthBloc(
      loginWithGoogleUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      authRepository: sl(),
    ),
  );

  // ============================================================================
  // Features - Finance
  // ============================================================================

  // Data Sources
  sl.registerLazySingleton<FinanceRemoteDataSource>(
    () => FinanceRemoteDataSourceImpl(supabaseClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(
      remoteDataSource: sl(),
      connectivityService: sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetNetworthUseCase(sl()));
  sl.registerLazySingleton(() => GetDailyChangeUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetsUseCase(sl()));
  sl.registerLazySingleton(() => WatchAssetsUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetQuantityUseCase(sl()));
  sl.registerLazySingleton(() => AddCryptoWalletUseCase(sl()));
  sl.registerLazySingleton(() => SearchStocksUseCase(sl()));
  sl.registerLazySingleton(() => AddStockUseCase(sl()));
  sl.registerLazySingleton(() => GetPlaidLinkTokenUseCase(sl()));
  sl.registerLazySingleton(() => ExchangePlaidTokenUseCase(sl()));
  sl.registerLazySingleton(() => GetWealthHistoryUseCase(sl()));
  sl.registerLazySingleton(() => AddManualAssetUseCase(sl()));
  sl.registerLazySingleton(() => AddAssetReminderUseCase(sl()));
  sl.registerLazySingleton(() => GetPortfolioInsightsUseCase(sl()));
  
  // Asset Detail Use Cases
  sl.registerLazySingleton(() => GetCryptoWalletDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetStockDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetBankAccountDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetManualAssetDetailsUseCase(sl()));
  
  // Asset Payout Use Cases
  sl.registerLazySingleton(() => GetAssetPayoutSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetPayoutsUseCase(sl()));
  sl.registerLazySingleton(() => MarkReminderAsReceivedUseCase(sl()));

  // BLoCs
  sl.registerFactory(
    () => FinanceBloc(
      getNetworthUseCase: sl(),
      getDailyChangeUseCase: sl(),
      getAssetsUseCase: sl(),
      watchAssetsUseCase: sl(),
      deleteAssetUseCase: sl(),
      updateAssetQuantityUseCase: sl(),
      addCryptoWalletUseCase: sl(),
      searchStocksUseCase: sl(),
      addStockUseCase: sl(),
      getPlaidLinkTokenUseCase: sl(),
      exchangePlaidTokenUseCase: sl(),
      getWealthHistoryUseCase: sl(),
      addManualAssetUseCase: sl(),
      addAssetReminderUseCase: sl(),
    ),
  );

  // Specialized BLoCs
  sl.registerFactory(
    () => DashboardBloc(
      getNetworthUseCase: sl(),
      getDailyChangeUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AssetsBloc(
      getAssetsUseCase: sl(),
      watchAssetsUseCase: sl(),
      addCryptoWalletUseCase: sl(),
      addStockUseCase: sl(),
      addManualAssetUseCase: sl(),
      updateAssetQuantityUseCase: sl(),
      financeRepository: sl(),
    ),
  );

  sl.registerFactory(
    () => InsightsBloc(
      getPortfolioInsightsUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => AssetDetailBloc(
      getCryptoWalletDetailsUseCase: sl(),
      getStockDetailsUseCase: sl(),
      getBankAccountDetailsUseCase: sl(),
      getManualAssetDetailsUseCase: sl(),
    ),
  );
  
  sl.registerFactory(
    () => ManualAssetDetailBloc(
      getAssetPayoutSummaryUseCase: sl(),
      getAssetPayoutsUseCase: sl(),
      markReminderAsReceivedUseCase: sl(),
    ),
  );
}
