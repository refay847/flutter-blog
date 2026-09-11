import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref)=>TokenStorage());
final apiClientProvider = Provider<ApiClient>((ref)=>ApiClient(ref.watch(tokenStorageProvider)));
final authRepositoryProvider = Provider<AuthRepository>((ref)=>AuthRepositoryImpl(AuthRemoteDataSource(ref.watch(apiClientProvider)),ref.watch(tokenStorageProvider)));
final authStateProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref)=>AuthNotifier(ref.watch(authRepositoryProvider)));

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository repo;
  AuthNotifier(this.repo):super(const AsyncLoading()) { _restore(); }
  Future<void> _restore() async { try { if (!await repo.hasSession()) { state=const AsyncData(null); return; } state=AsyncData(await repo.me()); } catch (_) { state=const AsyncData(null); } }
  Future<String?> login(String e,String p) async { state=const AsyncLoading(); try { final r=await repo.login(e,p); state=AsyncData(r.$1); return null; } catch(e){ state=const AsyncData(null); return e.toString(); } }
  Future<String?> register(String n,String e,String p,String c) async { state=const AsyncLoading(); try { final r=await repo.register(n,e,p,c); state=AsyncData(r.$1); return null; } catch(e){ state=const AsyncData(null); return e.toString(); } }
  Future<void> logout() async { await repo.logout(); state=const AsyncData(null); }
}
