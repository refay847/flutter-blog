import '../../../../core/network/api_client.dart';
import '../../domain/entities/user.dart';
class AuthRemoteDataSource {
  final ApiClient api; AuthRemoteDataSource(this.api);
  Future<(User,String)> login(String email,String password) async { try { final r=await api.post('/login',data:{'email':email,'password':password}); return (User.fromJson(Map<String,dynamic>.from(r.data['user'])),r.data['token'].toString()); } catch(e){throw api.exceptionFrom(e);} }
  Future<(User,String)> register(String name,String email,String password,String confirmation) async { try { final r=await api.post('/register',data:{'name':name,'email':email,'password':password,'password_confirmation':confirmation}); return (User.fromJson(Map<String,dynamic>.from(r.data['user'])),r.data['token'].toString()); } catch(e){throw api.exceptionFrom(e);} }
  Future<User> me() async { try { final r=await api.get('/user'); return User.fromJson(Map<String,dynamic>.from(r.data['user'])); } catch(e){throw api.exceptionFrom(e);} }
  Future<void> logout() async { try { await api.post('/logout'); } catch(e){throw api.exceptionFrom(e);} }
}
