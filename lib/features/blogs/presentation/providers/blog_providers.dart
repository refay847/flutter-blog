import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/blog_remote_data_source.dart';
import '../../data/repositories/blog_repository_impl.dart';
import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/blog_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final blogRepositoryProvider = Provider<BlogRepository>(
  (ref) => BlogRepositoryImpl(
    BlogRemoteDataSource(
      ref.watch(apiClientProvider),
    ),
  ),
);

final blogsProvider = AsyncNotifierProvider<BlogsNotifier, List<Blog>>(
  BlogsNotifier.new,
);

class BlogsNotifier extends AsyncNotifier<List<Blog>> {
  @override
  Future<List<Blog>> build() async {
    // Rebuild blogs whenever the logged-in user changes.
    ref.watch(authStateProvider);

    return ref.read(blogRepositoryProvider).all();
  }

  Future<void> refreshBlogs() async {
    state = await AsyncValue.guard(
      () => ref.read(blogRepositoryProvider).all(),
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<void> create(
    String name,
    String description,
    XFile? image,
  ) async {
    final blog = await ref
        .read(blogRepositoryProvider)
        .create(name, description, image);

    state = AsyncData([
      blog,
      ...(state.value ?? <Blog>[]),
    ]);
  }

  // ============================================================
  // UPDATE BLOG
  // ============================================================

  Future<void> updateBlog(
    int id,
    String name,
    String description,
    XFile? image,
  ) async {
    final blog = await ref
        .read(blogRepositoryProvider)
        .update(id, name, description, image);

    final blogs = state.value ?? <Blog>[];

    state = AsyncData(
      blogs.map((item) {
        if (item.id == id) {
          return blog;
        }

        return item;
      }).toList(),
    );
  }

  // ============================================================
  // DELETE BLOG
  // ============================================================

  Future<void> deleteBlog(int id) async {
    await ref.read(blogRepositoryProvider).delete(id);

    final blogs = state.value ?? <Blog>[];

    state = AsyncData(
      blogs.where((item) => item.id != id).toList(),
    );
  }

  // ============================================================
  // LIKE
  // ============================================================

  Future<void> toggleLike(Blog blog) async {
    final repository = ref.read(blogRepositoryProvider);

    final oldLiked = blog.isLiked;
    final oldCount = blog.likesCount;

    final newLiked = !oldLiked;

    final newCount = newLiked
        ? oldCount + 1
        : oldCount > 0
            ? oldCount - 1
            : 0;

    _replaceBlog(
      blog.copyWith(
        isLiked: newLiked,
        likesCount: newCount,
      ),
    );

    try {
      if (newLiked) {
        await repository.like(blog.id);
      } else {
        await repository.unlike(blog.id);
      }
    } catch (e) {
      _replaceBlog(
        blog.copyWith(
          isLiked: oldLiked,
          likesCount: oldCount,
        ),
      );

      rethrow;
    }
  }

  // ============================================================
  // COMMENTS
  // ============================================================

  Future<Comment> addComment(
    int blogId,
    String body,
  ) async {
    final comment = await ref
        .read(blogRepositoryProvider)
        .addComment(blogId, body);

    final blogs = state.value ?? <Blog>[];

    Blog? blog;

    for (final item in blogs) {
      if (item.id == blogId) {
        blog = item;
        break;
      }
    }

    if (blog != null) {
      final updatedComments = [
        ...blog.comments,
        comment,
      ];

      _replaceBlog(
        blog.copyWith(
          comments: updatedComments,
          commentsCount: updatedComments.length,
        ),
      );
    }

    return comment;
  }

  // ============================================================
  // UPDATE COMMENT
  // ============================================================

  Future<void> updateComment(
    int blogId,
    int commentId,
    String body,
  ) async {
    final repository = ref.read(blogRepositoryProvider);

    final updatedComment = await repository.updateComment(
      blogId,
      commentId,
      body,
    );

    final blogs = state.value;

    if (blogs == null) {
      return;
    }

    final updatedBlogs = blogs.map((blog) {
      if (blog.id != blogId) {
        return blog;
      }

      final updatedComments = blog.comments.map((comment) {
        if (comment.id == commentId) {
          return updatedComment;
        }

        return comment;
      }).toList();

      return blog.copyWith(
        comments: updatedComments,
      );
    }).toList();

    state = AsyncData(updatedBlogs);
  }

  // ============================================================
  // DELETE COMMENT
  // ============================================================

  Future<void> deleteComment(
    int blogId,
    int commentId,
  ) async {
    await ref
        .read(blogRepositoryProvider)
        .deleteComment(blogId, commentId);

    final blogs = state.value ?? <Blog>[];

    Blog? blog;

    for (final item in blogs) {
      if (item.id == blogId) {
        blog = item;
        break;
      }
    }

    if (blog != null) {
      final updatedComments = blog.comments
          .where((comment) => comment.id != commentId)
          .toList();

      _replaceBlog(
        blog.copyWith(
          comments: updatedComments,
          commentsCount: updatedComments.length,
        ),
      );
    }
  }

  // ============================================================
  // REPLACE BLOG
  // ============================================================

  void _replaceBlog(Blog updatedBlog) {
    final blogs = state.value ?? <Blog>[];

    state = AsyncData(
      blogs.map((blog) {
        if (blog.id == updatedBlog.id) {
          return updatedBlog;
        }

        return blog;
      }).toList(),
    );
  }
}