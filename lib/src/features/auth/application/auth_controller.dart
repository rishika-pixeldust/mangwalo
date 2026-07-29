import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../listings/application/listing_providers.dart';

/// Who the app is acting as.
///
/// Anonymous is a *real* Supabase user — a row in `auth.users` with a working
/// `auth.uid()` — not a placeholder. That matters: every RLS policy, foreign
/// key and booking flow behaves identically whether the session came from
/// anonymous sign-in or Google, so nothing here has to change when a stronger
/// provider is added later.
///
/// It is still not a durable identity: clearing browser storage loses the
/// account. Before this app owes anyone money, an anonymous session must be
/// upgraded via [linkGoogle] — see docs/product-roadmap.md.
sealed class AuthState {
  const AuthState();
}

/// No backend configured — local-only mode. Everything on-device still works.
class AuthUnavailable extends AuthState {
  const AuthUnavailable();
}

class SignedOut extends AuthState {
  const SignedOut();
}

class SignedIn extends AuthState {
  const SignedIn({
    required this.userId,
    required this.isAnonymous,
    this.email,
  });

  final String userId;

  /// True until the session is upgraded to a real identity.
  final bool isAnonymous;
  final String? email;

  /// A durable, portable identity — the precondition for owing someone money.
  bool get isDurable => !isAnonymous;
}

/// Session state, driven by Supabase's own auth stream so it cannot drift from
/// the client's actual token.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    if (!ref.watch(backendReadyProvider)) return const AuthUnavailable();

    final client = Supabase.instance.client;

    // Supabase is the source of truth; mirror it rather than tracking our own.
    final sub = client.auth.onAuthStateChange.listen((event) {
      state = _fromSession(event.session);
    });
    ref.onDispose(sub.cancel);

    return _fromSession(client.auth.currentSession);
  }

  static AuthState _fromSession(Session? session) {
    final user = session?.user;
    if (user == null) return const SignedOut();
    return SignedIn(
      userId: user.id,
      // Supabase marks anonymous users explicitly; treat a missing flag as
      // anonymous so an unknown session is never mistaken for a durable one.
      isAnonymous: user.isAnonymous ?? (user.email == null),
      email: user.email,
    );
  }

  /// Gives the app an identity without asking anything of the user. Called at
  /// bootstrap so the board can read and write immediately; a no-op if a
  /// session already exists.
  Future<void> ensureSession() async {
    if (state is AuthUnavailable || state is SignedIn) return;
    try {
      await Supabase.instance.client.auth.signInAnonymously();
    } on Object {
      // Provider disabled or offline — stay signed out and let the UI say so
      // rather than blocking the board behind an error.
    }
  }

  /// Upgrades an anonymous session to a durable Google identity, keeping the
  /// same user id — so listings, bookings and reputation survive the upgrade
  /// instead of being orphaned under a new account.
  Future<void> linkGoogle() async {
    if (state is! SignedIn) return;
    await Supabase.instance.client.auth.linkIdentity(OAuthProvider.google);
  }

  Future<void> signOut() async {
    if (state is AuthUnavailable) return;
    await Supabase.instance.client.auth.signOut();
  }
}

final authProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The signed-in user id, or null. Convenience for the many call sites that
/// only need "who am I".
final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is SignedIn ? auth.userId : null;
});

/// Whether an action that writes to the shared noticeboard can proceed at all.
/// Distinct from `may_transact()` on the server, which additionally requires
/// KYC — this is only "is there a session".
final canWriteProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is SignedIn;
});
