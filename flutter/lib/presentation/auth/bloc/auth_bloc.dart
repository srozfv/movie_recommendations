import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/api_client.dart';
import '../../../core/services/token_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiClient apiClient;
  final TokenService tokenService;

  AuthBloc({required this.apiClient, required this.tokenService})
      : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
    on<RegisterRequested>(_onRegisterRequested);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final hasToken = await tokenService.hasToken();
    if (hasToken) {
      emit(Authenticated());
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await apiClient.login(event.email, event.password);
      await tokenService.saveTokens(token.accessToken, token.refreshToken);
      emit(Authenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final token = await apiClient.register(
          event.username, event.email, event.password);
      await tokenService.saveTokens(token.accessToken, token.refreshToken);
      emit(Authenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    print('🚪 Выход из аккаунта...');
    // Очищаем токены
    await tokenService.clearTokens();
    
    // Сбрасываем флаг онбординга
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('onboarding_completed');
    print('✅ Флаг онбординга сброшен');
    
    emit(Unauthenticated());
  }
}