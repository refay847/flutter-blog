import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import '../models/blog_model.dart';
import '../models/comment_model.dart';

class BlogRemoteDataSource {
  final ApiClient api;

  BlogRemoteDataSource(this.api);

  Future<List<Blog>> all() async {
    try {
      final response = await api.get('/blogs');

      final blogs = response.data['blogs'] as List;

      return blogs
          .map(
            (item) => BlogModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<Blog> create(
    String name,
    String description,
    XFile? image,
  ) async {
    try {
      final data = FormData.fromMap({
        'name': name,
        'description': description,
      });

      if (image != null) {
        data.files.add(
          MapEntry(
            'img',
            await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          ),
        );
      }

      final response = await api.post(
        '/blogs',
        data: data,
      );

      return BlogModel.fromJson(
        Map<String, dynamic>.from(
          response.data['blog'],
        ),
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<Blog> update(
    int id,
    String name,
    String description,
    XFile? image,
  ) async {
    try {
      final data = FormData.fromMap({
        '_method': 'PUT',
        'name': name,
        'description': description,
      });

      if (image != null) {
        data.files.add(
          MapEntry(
            'img',
            await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          ),
        );
      }

      final response = await api.post(
        '/blogs/$id',
        data: data,
      );

      return BlogModel.fromJson(
        Map<String, dynamic>.from(
          response.data['blog'],
        ),
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await api.delete('/blogs/$id');
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  // ------------------------------------------------------------
  // LIKE
  // ------------------------------------------------------------

  Future<void> like(int blogId) async {
    try {
      await api.post(
        '/blogs/$blogId/like',
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<void> unlike(int blogId) async {
    try {
      await api.delete(
        '/blogs/$blogId/like',
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  // ------------------------------------------------------------
  // COMMENTS
  // ------------------------------------------------------------

  Future<Comment> addComment(
    int blogId,
    String body,
  ) async {
    try {
      final response = await api.post(
        '/blogs/$blogId/comments',
        data: {
          'body': body,
        },
      );

      final commentJson = response.data['comment'];

      return CommentModel.fromJson(
        Map<String, dynamic>.from(commentJson),
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<Comment> updateComment(
    int blogId,
    int commentId,
    String body,
  ) async {
    try {
      final response = await api.put(
        '/blogs/$blogId/comments/$commentId',
        data: {
          'body': body,
        },
      );

      final commentJson = response.data['comment'];

      return CommentModel.fromJson(
        Map<String, dynamic>.from(commentJson),
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }

  Future<void> deleteComment(
    int blogId,
    int commentId,
  ) async {
    try {
      await api.delete(
        '/blogs/$blogId/comments/$commentId',
      );
    } catch (e) {
      throw api.exceptionFrom(e);
    }
  }
}