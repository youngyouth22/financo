import 'package:bloc/bloc.dart';
import 'package:financo/di/injection_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingInitial()) {
    on<CompleteOnboardingRequested>(_onCompleteOnboardingRequested);
  }

  Future<void> _onCompleteOnboardingRequested(
    CompleteOnboardingRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(const OnboardingLoading());
    try {
      final prefs = sl<SharedPreferences>();
      await prefs.setBool('onboarding_seen', true);
      emit(const OnboardingSuccess());
    } catch (e) {
      emit(OnboardingFailure(e.toString()));
    }
  }
}
