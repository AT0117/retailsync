import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

// ─── Auth State ────────────────────────────────────────────────────────

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AppAuthState {
  final AuthStatus status;
  final String? role; // 'admin' or 'customer'
  final String? userId;
  final String? errorMessage;

  const AppAuthState({
    this.status = AuthStatus.initial,
    this.role,
    this.userId,
    this.errorMessage,
  });

  AppAuthState copyWith({
    AuthStatus? status,
    String? role,
    String? userId,
    String? errorMessage,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      errorMessage: errorMessage,
    );
  }
}

// ─── Auth Notifier ──────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AppAuthState> {
  final SupabaseService _service;

  AuthNotifier(this._service) : super(const AppAuthState());

  /// Check if user is already signed in on app start
  Future<void> checkSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final uid = _service.currentUserId;
      if (uid == null) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return;
      }
      final role = await _service.getUserRole(uid);
      state = AppAuthState(
        status: AuthStatus.authenticated,
        role: role,
        userId: uid,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _service.signIn(
        email: email,
        password: password,
      );
      final uid = response.user?.id;
      if (uid == null) throw Exception('Sign-in failed');

      final role = await _service.getUserRole(uid);
      state = AppAuthState(
        status: AuthStatus.authenticated,
        role: role,
        userId: uid,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    required String fullName,
    String? mobileNumber,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _service.signUp(
        email: email,
        password: password,
        role: role,
        fullName: fullName,
        mobileNumber: mobileNumber,
      );
      final uid = response.user?.id;
      if (uid == null) throw Exception('Sign-up failed');

      state = AppAuthState(
        status: AuthStatus.authenticated,
        role: role,
        userId: uid,
      );
    } catch (e) {
      state = AppAuthState(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AppAuthState(status: AuthStatus.unauthenticated);
  }
}

// ─── Providers ──────────────────────────────────────────────────────────

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final authProvider = StateNotifierProvider<AuthNotifier, AppAuthState>((ref) {
  final service = ref.read(supabaseServiceProvider);
  return AuthNotifier(service);
});
