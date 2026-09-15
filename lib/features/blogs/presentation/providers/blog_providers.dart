import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/blog_remote_data_source.dart';
import '../../data/models/blog_model.dart';
import '../../data/models/pending_action.dart';
import '../../data/repositories/blog_repository_impl.dart';
import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/blog_repository.dart';
import '../../../../core/network/connectivity_provider.dart';
import '../../../../core/storage/local_cache_service.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/models/comment_model.dart';

const _cachedBlogsLimit = 10;

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
    // Rebuild blogs whenever the logged-in user changes, and whenever
    // connectivity flips (so reconnecting auto-refreshes + syncs).
    ref.watch(authStateProvider);
    final isOnline = ref.watch(isOnlineProvider);

    final cache = ref.read(localCacheServiceProvider);

    if (!isOnline) {
      final cachedJson = await cache.getBlogs();
      return cachedJson.map(BlogModel.fromJson).toList();
    }

    try {
      await syncPendingActions();
      final blogs = await ref.read(blogRepositoryProvider).all();
      await _cacheBlogs(blogs);
      return blogs;
    } catch (e) {
      // Network call failed even though connectivity looked fine (e.g. DNS
      // hiccup, server down) — fall back to cache instead of a hard error.
      final cachedJson = await cache.getBlogs();
      if (cachedJson.isNotEmpty) {
        return cachedJson.map(BlogModel.fromJson).toList();
      }
      rethrow;
    }
  }

  Future<void> refreshBlogs() async {
    if (!ref.read(isOnlineProvider)) return; // nothing to pull, stay on cache

    state = await AsyncValue.guard(() async {
      await syncPendingActions();
      final blogs = await ref.read(blogRepositoryProvider).all();
      await _cacheBlogs(blogs);
      return blogs;
    });
  }

  // ============================================================
  // CACHE HELPERS
  // ============================================================

  Future<void> _cacheBlogs(List<Blog> blogs) async {
    final cache = ref.read(localCacheServiceProvider);
    final toCache = blogs.take(_cachedBlogsLimit).map(_toBlogModel).toList();
    await cache.saveBlogs(toCache.map((b) => b.toJson()).toList());
  }

  Future<void> _persistCurrentState() async {
    final blogs = state.value;
    if (blogs != null) await _cacheBlogs(blogs);
  }

  BlogModel _toBlogModel(Blog blog) {
    if (blog is BlogModel) return blog;
    return BlogModel(
      id: blog.id,
      userId: blog.userId,
      name: blog.name,
      description: blog.description,
      img: blog.img,
      authorName: blog.authorName,
      likesCount: blog.likesCount,
      commentsCount: blog.commentsCount,
      isLiked: blog.isLiked,
      comments: blog.comments,
    );
  }

  // ============================================================
  // CREATE / UPDATE / DELETE BLOG (unchanged — still require internet)
  // ============================================================

  Future<void> create(String name, String description, XFile? image) async {
    final blog =
        await ref.read(blogRepositoryProvider).create(name, description, image);

    state = AsyncData([blog, ...(state.value ?? <Blog>[])]);
    await _persistCurrentState();
  }

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
      blogs.map((item) => item.id == id ? blog : item).toList(),
    );
    await _persistCurrentState();
  }

  Future<void> deleteBlog(int id) async {
    await ref.read(blogRepositoryProvider).delete(id);

    final blogs = state.value ?? <Blog>[];
    state = AsyncData(blogs.where((item) => item.id != id).toList());
    await _persistCurrentState();
  }

  // ============================================================
  // LIKE (offline-aware)
  // ============================================================

  Future<void> toggleLike(Blog blog) async {
    final repository = ref.read(blogRepositoryProvider);

    final oldLiked = blog.isLiked;
    final oldCount = blog.likesCount;
    final newLiked = !oldLiked;
    final newCount =
        newLiked ? oldCount + 1 : (oldCount > 0 ? oldCount - 1 : 0);

    _replaceBlog(blog.copyWith(isLiked: newLiked, likesCount: newCount));
    await _persistCurrentState();

    if (!ref.read(isOnlineProvider)) {
      await _queueAction(
        type: newLiked ? PendingActionType.like : PendingActionType.unlike,
        blogId: blog.id,
      );
      return;
    }

    try {
      if (newLiked) {
        await repository.like(blog.id);
      } else {
        await repository.unlike(blog.id);
      }
    } catch (e) {
      if (!ref.read(isOnlineProvider)) {
        // Went offline mid-request — keep the optimistic UI, queue for later.
        await _queueAction(
          type: newLiked ? PendingActionType.like : PendingActionType.unlike,
          blogId: blog.id,
        );
        return;
      }

      _replaceBlog(blog.copyWith(isLiked: oldLiked, likesCount: oldCount));
      await _persistCurrentState();
      rethrow;
    }
  }

  // ============================================================
  // COMMENTS (offline-aware for adding; edit/delete still need internet)
  // ============================================================

  Future<Comment> addComment(int blogId, String body) async {
    final repository = ref.read(blogRepositoryProvider);

    if (!ref.read(isOnlineProvider)) {
      return _addLocalPendingComment(blogId, body);
    }

    try {
      final comment = await repository.addComment(blogId, body);
      _appendComment(blogId, comment);
      await _persistCurrentState();
      return comment;
    } catch (e) {
      if (!ref.read(isOnlineProvider)) {
        return _addLocalPendingComment(blogId, body);
      }
      rethrow;
    }
  }

  Future<Comment> _addLocalPendingComment(int blogId, String body) async {
    final currentUser = ref.read(authStateProvider).value;

    final tempComment = CommentModel(
      id: -DateTime.now().microsecondsSinceEpoch, // negative = local/pending
      userId: currentUser?.id ?? 0,
      blogId: blogId,
      body: body,
      userName: 'You (pending)',
    );

    _appendComment(blogId, tempComment);
    await _persistCurrentState();

    await _queueAction(
      type: PendingActionType.addComment,
      blogId: blogId,
      commentBody: body,
    );

    return tempComment;
  }

  Future<void> updateComment(int blogId, int commentId, String body) async {
    final updatedComment = await ref
        .read(blogRepositoryProvider)
        .updateComment(blogId, commentId, body);

    final blogs = state.value;
    if (blogs == null) return;

    final updatedBlogs = blogs.map((blog) {
      if (blog.id != blogId) return blog;
      final updatedComments = blog.comments
          .map((c) => c.id == commentId ? updatedComment : c)
          .toList();
      return blog.copyWith(comments: updatedComments);
    }).toList();

    state = AsyncData(updatedBlogs);
    await _persistCurrentState();
  }

  Future<void> deleteComment(int blogId, int commentId) async {
    await ref.read(blogRepositoryProvider).deleteComment(blogId, commentId);

    final blogs = state.value ?? <Blog>[];
    Blog? blog;
    for (final item in blogs) {
      if (item.id == blogId) {
        blog = item;
        break;
      }
    }

    if (blog != null) {
      final updatedComments =
          blog.comments.where((c) => c.id != commentId).toList();
      _replaceBlog(blog.copyWith(
        comments: updatedComments,
        commentsCount: updatedComments.length,
      ));
      await _persistCurrentState();
    }
  }

  void _appendComment(int blogId, Comment comment) {
    final blogs = state.value ?? <Blog>[];
    Blog? blog;
    for (final item in blogs) {
      if (item.id == blogId) {
        blog = item;
        break;
      }
    }
    if (blog == null) return;

    final updatedComments = [...blog.comments, comment];
    _replaceBlog(blog.copyWith(
      comments: updatedComments,
      commentsCount: updatedComments.length,
    ));
  }

  void _replaceBlog(Blog updatedBlog) {
    final blogs = state.value ?? <Blog>[];
    state = AsyncData(
      blogs.map((blog) => blog.id == updatedBlog.id ? updatedBlog : blog).toList(),
    );
  }

  // ============================================================
  // OFFLINE QUEUE
  // ============================================================

  Future<void> _queueAction({
    required PendingActionType type,
    required int blogId,
    String? commentBody,
  }) async {
    final cache = ref.read(localCacheServiceProvider);
    final action = PendingAction(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      type: type,
      blogId: blogId,
      commentBody: commentBody,
      createdAt: DateTime.now(),
    );
    await cache.addPendingAction(action.toJson());
  }

  /// Replays queued likes/unlikes/comments against the API. Actions that
  /// still fail (e.g. still offline) stay queued for the next attempt.
  Future<void> syncPendingActions() async {
    final cache = ref.read(localCacheServiceProvider);
    final repository = ref.read(blogRepositoryProvider);

    final rawActions = await cache.getPendingActions();
    if (rawActions.isEmpty) return;

    final actions = rawActions.map(PendingAction.fromJson).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final stillPending = <PendingAction>[];

    for (final action in actions) {
      try {
        switch (action.type) {
          case PendingActionType.like:
            await repository.like(action.blogId);
            break;
          case PendingActionType.unlike:
            await repository.unlike(action.blogId);
            break;
          case PendingActionType.addComment:
            await repository.addComment(
              action.blogId,
              action.commentBody ?? '',
            );
            break;
        }
      } catch (_) {
        stillPending.add(action);
      }
    }

    await cache.savePendingActions(
      stillPending.map((a) => a.toJson()).toList(),
    );
  }
}