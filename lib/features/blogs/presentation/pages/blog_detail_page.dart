import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import '../providers/blog_providers.dart';

class BlogDetailPage extends ConsumerStatefulWidget {
  final Blog blog;

  // ID of the currently logged-in user.
  final int currentUserId;

  const BlogDetailPage({
    super.key,
    required this.blog,
    required this.currentUserId,
  });

  @override
  ConsumerState<BlogDetailPage> createState() =>
      _BlogDetailPageState();
}

class _BlogDetailPageState
    extends ConsumerState<BlogDetailPage> {
  late final TextEditingController commentController;

  bool sendingComment = false;

  @override
  void initState() {
    super.initState();

    commentController = TextEditingController();
  }

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  Blog get currentBlog {
    final blogs = ref.read(blogsProvider).value;

    if (blogs == null || blogs.isEmpty) {
      return widget.blog;
    }

    for (final blog in blogs) {
      if (blog.id == widget.blog.id) {
        return blog;
      }
    }

    return widget.blog;
  }

  Future<void> toggleLike() async {
    try {
      await ref
          .read(blogsProvider.notifier)
          .toggleLike(currentBlog);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> sendComment() async {
    final body = commentController.text.trim();

    if (body.isEmpty || sendingComment) {
      return;
    }

    setState(() {
      sendingComment = true;
    });

    try {
      await ref
          .read(blogsProvider.notifier)
          .addComment(
            currentBlog.id,
            body,
          );

      commentController.clear();

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          sendingComment = false;
        });
      }
    }
  }

  Future<void> deleteComment(
    Comment comment,
  ) async {
    try {
      await ref
          .read(blogsProvider.notifier)
          .deleteComment(
            currentBlog.id,
            comment.id,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> editComment(
    Comment comment,
  ) async {
    final controller = TextEditingController(
      text: comment.body,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit comment',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: 'Write your comment...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  return;
                }

                Navigator.of(context).pop(text);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null || result.isEmpty) {
      return;
    }

    if (result == comment.body) {
      return;
    }

    try {
      await ref
          .read(blogsProvider.notifier)
          .updateComment(
            currentBlog.id,
            comment.id,
            result,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment updated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  Future<void> confirmDeleteComment(
    Comment comment,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete comment?',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This comment will be permanently deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await deleteComment(comment);
    }
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT:
    // watch() makes this page rebuild when blogsProvider changes.
    //
    // This fixes the like button not changing until leaving
    // and reopening the page.
    final blogsState = ref.watch(blogsProvider);

    Blog blog = widget.blog;

    final blogs = blogsState.value;

    if (blogs != null) {
      for (final item in blogs) {
        if (item.id == widget.blog.id) {
          blog = item;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Story',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          22,
          4,
          22,
          40,
        ),
        children: [
          if (blog.img != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CachedNetworkImage(
                imageUrl:
                    '${AppConstants.storageBaseUrl}${blog.img}',
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
                errorWidget: (
                  context,
                  url,
                  error,
                ) {
                  return const SizedBox(
                    height: 240,
                    child: ColoredBox(
                      color: Colors.black12,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 42,
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),

          Text(
            blog.name,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              CircleAvatar(
                radius: 18,
                child: Text(
                  blog.authorName.isNotEmpty
                      ? blog.authorName[0].toUpperCase()
                      : 'U',
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  blog.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            blog.description,
            style: const TextStyle(
              fontSize: 17,
              height: 1.7,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 24),

          _EngagementBar(
            blog: blog,
            onLike: toggleLike,
          ),

          const SizedBox(height: 30),

          const Text(
            'Comments',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 14),

          _CommentInput(
            controller: commentController,
            loading: sendingComment,
            onSend: sendComment,
          ),

          const SizedBox(height: 20),

          if (blog.comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 30,
              ),
              child: Center(
                child: Text(
                  'No comments yet.\nBe the first to comment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            )
          else
            ...blog.comments.map(
              (comment) {
                final isOwner =
                    comment.userId == widget.currentUserId;

                return _CommentTile(
                  comment: comment,
                  isOwner: isOwner,
                  onEdit: () {
                    editComment(comment);
                  },
                  onDelete: () {
                    confirmDeleteComment(comment);
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _EngagementBar extends StatelessWidget {
  final Blog blog;
  final VoidCallback onLike;

  const _EngagementBar({
    required this.blog,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onLike,
            icon: Icon(
              blog.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: blog.isLiked ? Colors.red : null,
            ),
          ),

          Text(
            '${blog.likesCount}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(width: 18),

          const Icon(
            Icons.chat_bubble_outline_rounded,
            size: 22,
          ),

          const SizedBox(width: 7),

          Text(
            '${blog.commentsCount}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),

          const Spacer(),

          const Text(
            'Engagement',
            style: TextStyle(
              color: Colors.black45,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _CommentInput({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: 4,
            minLines: 1,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Write a comment...',
              filled: true,
              fillColor: Colors.black.withValues(
                alpha: 0.04,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        IconButton.filled(
          onPressed: loading ? null : onSend,
          icon: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.send_rounded,
                ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 19,
            child: Text(
              comment.userName.isNotEmpty
                  ? comment.userName[0].toUpperCase()
                  : 'U',
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.04,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),

                      // Only show the menu for the owner.
                      if (isOwner)
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          iconSize: 19,
                          onSelected: (value) {
                            if (value == 'edit') {
                              onEdit();
                            }

                            if (value == 'delete') {
                              onDelete();
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Delete'),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    comment.body,
                    style: const TextStyle(
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}