import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/data/repositories/auth_repository.dart';
import '../../../core/services/session_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SessionService _sessionService;

  AuthBloc({
    required AuthRepository authRepository,
    required SessionService sessionService,
  })  : _authRepository = authRepository,
        _sessionService = sessionService,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUpdateProfile>(_onAuthUpdateProfile);
    on<AuthChangePassword>(_onAuthChangePassword);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      if (_sessionService.isLoggedIn()) {
        final userId = _sessionService.getUserId();
        if (userId != null) {
          final user = await _authRepository.getUserById(userId);
          if (user != null) {
            emit(AuthAuthenticated(user));
            return;
          }
        }
      }

      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      await _sessionService.saveSession(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());

      final user = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      await _sessionService.saveSession(user);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      emit(const AuthLoading());
      await _authRepository.logout();
      await _sessionService.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthUpdateProfile(
    AuthUpdateProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is! AuthAuthenticated) return;

      emit(const AuthLoading());

      final currentUser = (state as AuthAuthenticated).user;
      final userId = currentUser.id;

      if (userId == null) {
        emit(const AuthError('Usuario no encontrado'));
        return;
      }

      await _authRepository.updateProfile(
        userId: userId,
        name: event.name,
        email: event.email,
      );

      final updatedUser = await _authRepository.getUserById(userId);
      if (updatedUser != null) {
        await _sessionService.saveSession(updatedUser);
        emit(AuthProfileUpdated(updatedUser));
        emit(AuthAuthenticated(updatedUser));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAuthChangePassword(
    AuthChangePassword event,
    Emitter<AuthState> emit,
  ) async {
    try {
      if (state is! AuthAuthenticated) return;

      emit(const AuthLoading());

      final currentUser = (state as AuthAuthenticated).user;
      final userId = currentUser.id;

      if (userId == null) {
        emit(const AuthError('Usuario no encontrado'));
        return;
      }

      await _authRepository.changePassword(
        userId: userId,
        currentPassword: event.currentPassword,
        newPassword: event.newPassword,
      );

      emit(const AuthPasswordChanged());
      emit(AuthAuthenticated(currentUser));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
