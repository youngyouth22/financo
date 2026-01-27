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
import 'package:financo/features/finance/domain/usecases/add_crypto_wallet_usecase.dart';
import 'package:financo/features/finance/domain/usecases/add_stock_usecase.dart';
import 'package:financo/features/finance/domain/usecases/delete_asset_usecase.dart';
import 'package:financo/features/finance/domain/usecases/exchange_plaid_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_assets_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_daily_change_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_networth_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_plaid_link_token_usecase.dart';
import 'package:financo/features/finance/domain/usecases/get_wealth_history_usecase.dart';
import 'package:financo/features/finance/domain/usecases/search_stocks_usecase.dart';
import 'package:financo/features/finance/domain/usecases/update_asset_quantity_usecase.dart';
import 'package:financo/features/finance/domain/usecases/watch_assets_usecase.dart';
import 'package:financo/features/finance/presentation/bloc/finance_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  // Initialisation de Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );

  // Enregistrement du client Supabase
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

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
    () => FinanceRepositoryImpl(remoteDataSource: sl()),
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

  // BLoC
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
    ),
  );
}
