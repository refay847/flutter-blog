import 'package:image_picker/image_picker.dart';

import '../entities/blog.dart';
import '../entities/comment.dart';

abstract class BlogRepository {
  Future<List<Blog>> all();

  Future<Blog> create(
    String name,
    String description,
    XFile? image,
  );

  Future<Blog> update(
    int id,
    String name,
    String description,
    XFile? image,
  );

  Future<void> delete(int id);

  Future<void> like(int blogId);

  Future<void> unlike(int blogId);

  Future<Comment> addComment(
    int blogId,
    String body,
  );

  Future<Comment> updateComment(
    int blogId,
    int commentId,
    String body,
  );

  Future<void> deleteComment(
    int blogId,
    int commentId,
  );
}