import 'package:image_picker/image_picker.dart';
import '../../domain/entities/blog.dart';
import '../../domain/repositories/blog_repository.dart';
import '../datasources/blog_remote_data_source.dart';
class BlogRepositoryImpl implements BlogRepository { final BlogRemoteDataSource remote; BlogRepositoryImpl(this.remote); @override Future<List<Blog>> all()=>remote.all(); @override Future<Blog> create(String n,String d,XFile? i)=>remote.create(n,d,i); @override Future<Blog> update(int id,String n,String d,XFile? i)=>remote.update(id,n,d,i); @override Future<void> delete(int id)=>remote.delete(id); }
