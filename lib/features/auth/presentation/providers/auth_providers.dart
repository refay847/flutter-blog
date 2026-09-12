import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    ref.watch(tokenStorageProvider),
  ),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    AuthRemoteDataSource(
      ref.watch(apiClientProvider),
    ),
    ref.watch(tokenStorageProvider),
  ),
);

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(
    ref.watch(authRepositoryProvider),
  ),
);

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository repo;

  AuthNotifier(this.repo)
      : super(const AsyncLoading()) {
    _restore();
  }

  // ============================================================
  // RESTORE SESSION
  // ============================================================

  Future<void> _restore() async {
    try {
      final hasSession = await repo.hasSession();

      if (!hasSession) {
        state = const AsyncData(null);
        return;
      }

      final user = await repo.me();

      state = AsyncData(user);
    } catch (_) {
      state = const AsyncData(null);
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<String?> login(
    String email,
    String password,
  ) async {
    state = const AsyncLoading();

    try {
      final result = await repo.login(
        email,
        password,
      );

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
      state = const AsyncData(null);
    }
  }
}