import '../../domain/entities/user.dart';
class UserModel extends User { const UserModel({required super.id, required super.name, required super.email}); factory UserModel.fromJson(Map<String,dynamic> json) => UserModel(id:(json['id'] as num).toInt(), name:json['name']?.toString()??'', email:json['email']?.toString()??''); }
