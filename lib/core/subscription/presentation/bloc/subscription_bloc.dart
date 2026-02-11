import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:financo/core/services/subscription_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

// --- Events ---
abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
  @override
  List<Object?> get props => [];
}

class CheckSubscriptionStatusEvent extends SubscriptionEvent {
  final CustomerInfo? info;
  const CheckSubscriptionStatusEvent({this.info});
  @override
  List<Object?> get props => [info];
}

class PurchasePackageEvent extends SubscriptionEvent {
  final Package package;
  const PurchasePackageEvent(this.package);
  @override
  List<Object?> get props => [package];
}

class RestorePurchasesEvent extends SubscriptionEvent {}

// --- State ---
enum SubscriptionStatus { unknown, free, premium }

class SubscriptionState extends Equatable {
  final SubscriptionStatus status;
  final bool isLoading;
  final String? errorMessage;

  const SubscriptionState({
    this.status = SubscriptionStatus.unknown,
    this.isLoading = false,
    this.errorMessage,
  });

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, isLoading, errorMessage];
}

// --- Bloc ---
class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionService _subscriptionService;
  StreamSubscription? _customerInfoSubscription;

  SubscriptionBloc(this._subscriptionService)
    : super(const SubscriptionState()) {
    on<CheckSubscriptionStatusEvent>(_onCheckStatus);
    on<PurchasePackageEvent>(_onPurchasePackage);
    on<RestorePurchasesEvent>(_onRestorePurchases);

    // Listen to RevenueCat changes in real-time
    _customerInfoSubscription = _subscriptionService.customerInfoStream.listen((
      info,
    ) {
      add(CheckSubscriptionStatusEvent(info: info));
    });
  }

  Future<void> _onCheckStatus(
    CheckSubscriptionStatusEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final CustomerInfo? currentInfo =
        event.info ?? await _subscriptionService.getCustomerInfo();
    final isPremium = await _subscriptionService.isPremium(info: currentInfo);

    emit(
      state.copyWith(
        status: isPremium
            ? SubscriptionStatus.premium
            : SubscriptionStatus.free,
        isLoading: false,
      ),
    );
  }

  Future<void> _onPurchasePackage(
    PurchasePackageEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    final success = await _subscriptionService.purchasePackage(event.package);
    if (success) {
      // Status update will be handled by the stream listener
      emit(state.copyWith(isLoading: false));
    } else {
      emit(state.copyWith(isLoading: false, errorMessage: 'Purchase failed'));
    }
  }

  Future<void> _onRestorePurchases(
    RestorePurchasesEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    await _subscriptionService.restorePurchases();
    // Status update will be handled by the stream listener or manually checked if needed
    final isPremium = await _subscriptionService.isPremium();
    emit(
      state.copyWith(
        status: isPremium
            ? SubscriptionStatus.premium
            : SubscriptionStatus.free,
        isLoading: false,
      ),
    );
  }

  @override
  Future<void> close() {
    _customerInfoSubscription?.cancel();
    return super.close();
  }
}
