import 'package:image_picker/image_picker.dart';
import '../entities/blog.dart';
abstract class BlogRepository { Future<List<Blog>> all(); Future<Blog> create(String name,String description,XFile? image); Future<Blog> update(int id,String name,String description,XFile? image); Future<void> delete(int id); }
