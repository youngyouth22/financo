import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:financo/core/usecase/usecase.dart';
import 'package:financo/features/auth/domain/repositories/auth_repository.dart';
import 'package:financo/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:financo/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:financo/features/auth/domain/usecases/logout_usecase.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:financo/features/auth/presentation/bloc/auth_state.dart';

/// BLoC gérant l'état d'authentification de l'application.
///
/// Ce BLoC orchestre les cas d'utilisation d'authentification et
/// maintient l'état d'authentification de l'utilisateur.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginWithGoogleUseCase loginWithGoogleUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRepository authRepository;

  StreamSubscription? _authStateSubscription;

  AuthBloc({
    required this.loginWithGoogleUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.authRepository,
  }) : super(const AuthInitial()) {
    // Enregistrement des handlers d'événements
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthGoogleSignInRequested>(_onAuthGoogleSignInRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);

    // Écoute des changements d'état d'authentification
    _authStateSubscription = authRepository.authStateChanges.listen((user) {
      // N'émettre que si on n'est pas déjà en cours de traitement
      if (state is! AuthLoading) {
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      }
    });
  }

  /// Handler pour vérifier l'état d'authentification actuel.
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await getCurrentUserUseCase(const NoParams());

    result.fold((failure) => emit(AuthError(failure.message)), (user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    });
  }

  /// Handler pour la connexion avec Google.
  Future<void> _onAuthGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await loginWithGoogleUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(Authenticated(user)),
    );
  }

  /// Handler pour la déconnexion.
  Future<void> _onAuthSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await logoutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Handler pour les changements d'état d'authentification externes.
  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    if (event.isAuthenticated) {
      // L'état sera mis à jour par le stream authStateChanges
    } else {
      emit(const Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
