import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(tokenStorageProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(apiClientProvider)),
    ref.watch(tokenStorageProvider),
  ),
);

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
      (ref) => AuthNotifier(
        ref.watch(authRepositoryProvider),
        ref.watch(tokenStorageProvider),
        ref,
      ),
    );

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository repo;
  final TokenStorage storage;
  final Ref ref;

  AuthNotifier(this.repo, this.storage, this.ref)
      : super(const AsyncLoading()) {
    _restore();
  }

  // ============================================================
  // RESTORE SESSION (offline-aware)
  // ============================================================

  Future<void> _restore() async {
    try {
      final hasSession = await repo.hasSession();

      if (!hasSession) {
        state = const AsyncData(null);
        return;
      }

      // No connectivity: trust the cached user rather than forcing a
      // logout just because we can't reach /me right now.
      if (!ref.read(isOnlineProvider)) {
        final cached = await _cachedUser();
        state = AsyncData(cached); // null cached => falls back to login
        return;
      }

      final user = await repo.me();
      await storage.saveUser(user.toJson()); // keep the offline copy fresh
      state = AsyncData(user);
    } catch (_) {
      // repo.me() threw even though connectivity looked fine (DNS hiccup,
      // server down, etc.) — still prefer a cached session over logging
      // the user out.
      final cached = await _cachedUser();
      state = AsyncData(cached);
    }
  }

  Future<User?> _cachedUser() async {
    final json = await storage.getUser();
    if (json == null) return null;
    return User.fromJson(json);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();

    try {
      final result = await repo.login(email, password);
      await storage.saveUser(result.$1.toJson());
      state = AsyncData(result.$1);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      return e.toString();
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<String?> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    state = const AsyncLoading();

    try {
      final result = await repo.register(
        name,
        email,
        password,
        passwordConfirmation,
      );
      await storage.saveUser(result.$1.toJson());
      state = AsyncData(result.$1);
      return null;
    } catch (e) {
      state = const AsyncData(null);
      return e.toString();
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await repo.logout();
    } finally {
      await ref.read(localCacheServiceProvider).clearAll();
      state = const AsyncData(null);
    }
  }
}