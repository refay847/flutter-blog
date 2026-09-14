import '../entities/user.dart';

abstract class AuthRepository {
  Future<(User user, String token)> login(String email, String password);
  Future<(User user, String token)> register(
    String name,
    String email,
    String password,
    String confirmation,
  );
  Future<User> me();
  Future<void> logout();
  Future<bool> hasSession();
}
