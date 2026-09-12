import 'package:image_picker/image_picker.dart';

import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/blog_repository.dart';
import '../datasources/blog_remote_data_source.dart';

class BlogRepositoryImpl implements BlogRepository {
  final BlogRemoteDataSource remoteDataSource;

  BlogRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Blog>> all() {
    return remoteDataSource.all();
  }

  @override
  Future<Blog> create(
    String name,
    String description,
    XFile? image,
  ) {
    return remoteDataSource.create(
      name,
      description,
      image,
    );
  }

  @override
  Future<Blog> update(
    int id,
    String name,
    String description,
    XFile? image,
  ) {
    return remoteDataSource.update(
      id,
      name,
      description,
      image,
    );
  }

  @override
  Future<void> delete(int id) {
    return remoteDataSource.delete(id);
  }

  @override
  Future<void> like(int blogId) {
    return remoteDataSource.like(blogId);
  }

  @override
  Future<Comment> updateComment(
    int blogId,
    int commentId,
    String body,
  ) {
    return remoteDataSource.updateComment(
      blogId,
      commentId,
      body,
    );
  }

  @override
  Future<void> unlike(int blogId) {
    return remoteDataSource.unlike(blogId);
  }

  @override
  Future<Comment> addComment(
    int blogId,
    String body,
  ) {
    return remoteDataSource.addComment(
      blogId,
      body,
    );
  }

  @override
  Future<void> deleteComment(
    int blogId,
    int commentId,
  ) {
    return remoteDataSource.deleteComment(
      blogId,
      commentId,
    );
  }
}