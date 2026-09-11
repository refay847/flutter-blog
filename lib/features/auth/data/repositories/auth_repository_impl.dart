import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../../../../core/storage/token_storage.dart';
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remote; final TokenStorage storage;
  AuthRepositoryImpl(this.remote,this.storage);
  Future<(User,String)> _persist(Future<(User,String)> request) async { final result=await request; await storage.saveToken(result.$2); await storage.saveUser(result.$1.toJson()); return result; }
  @override Future<(User,String)> login(String e,String p)=>_persist(remote.login(e,p));
  @override Future<(User,String)> register(String n,String e,String p,String c)=>_persist(remote.register(n,e,p,c));
  @override Future<User> me() async { final user=await remote.me(); await storage.saveUser(user.toJson()); return user; }
  @override Future<void> logout() async { try { await remote.logout(); } finally { await storage.clear(); } }
  @override Future<bool> hasSession() async => (await storage.getToken()) != null;
}
