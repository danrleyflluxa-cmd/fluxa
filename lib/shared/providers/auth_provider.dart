import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

// ── Estado de Auth ─────────────────────────────────────────────────────────────
enum AuthStatus { loading, unauthenticated, authenticated, needsOnboarding }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? error;

  const AuthState({
    required this.status,
    this.user,
    this.error,
  });

  const AuthState.loading()        : status = AuthStatus.loading,        user = null, error = null;
  const AuthState.unauthenticated(): status = AuthStatus.unauthenticated, user = null, error = null;

  AuthState copyWith({AuthStatus? status, User? user, String? error}) => AuthState(
    status: status ?? this.status,
    user:   user   ?? this.user,
    error:  error,
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Escuta mudanças de sessão em tempo real e cancela ao dispose
    final sub = ref.read(supabaseClientProvider).auth.onAuthStateChange.listen((data) {
      _handleAuthChange(data.session);
    });
    ref.onDispose(sub.cancel);

    final session = ref.read(supabaseClientProvider).auth.currentSession;
    if (session == null) return const AuthState.unauthenticated();

    // Verifica perfil em background
    _checkProfile(session.user);
    return AuthState(status: AuthStatus.loading, user: session.user);
  }

  Future<void> _handleAuthChange(Session? session) async {
    if (session == null) {
      state = const AuthState.unauthenticated();
      return;
    }
    await _checkProfile(session.user);
  }

  Future<void> _checkProfile(User user) async {
    try {
      final client = ref.read(supabaseClientProvider);
      final data = await client
          .from('profiles')
          .select('user_type')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        state = AuthState(status: AuthStatus.needsOnboarding, user: user);
      } else {
        state = AuthState(status: AuthStatus.authenticated, user: user);
      }
    } on AuthException {
      // Sessão expirou durante a verificação
      state = const AuthState.unauthenticated();
    } catch (_) {
      state = AuthState(status: AuthStatus.needsOnboarding, user: user);
    }
  }

  // ── Ações ──────────────────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: _mapError(e.message));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = const AuthState.loading();
    try {
      final client = ref.read(supabaseClientProvider);
      await client.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: _mapError(e.message));
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AuthState.loading();
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOAuth(OAuthProvider.google);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  Future<void> signInWithApple() async {
    state = const AuthState.loading();
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOAuth(OAuthProvider.apple);
    } on AuthException catch (e) {
      state = AuthState(status: AuthStatus.unauthenticated, error: e.message);
    }
  }

  Future<void> signOut() async {
    state = const AuthState.loading();
    await ref.read(supabaseClientProvider).auth.signOut();
    state = const AuthState.unauthenticated();
  }

  Future<void> refreshProfile() async {
    final user = state.user;
    if (user == null) return;
    await _checkProfile(user);
  }

  String _mapError(String msg) {
    if (msg.contains('Invalid login')) return 'E-mail ou senha incorretos.';
    if (msg.contains('Email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
    if (msg.contains('already registered')) return 'Este e-mail já está cadastrado.';
    return msg;
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

// Atalho para o userId atual — usado em toda a app
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});
