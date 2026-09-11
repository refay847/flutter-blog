import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/blog.dart';
import '../providers/blog_providers.dart';
import 'blog_detail_page.dart';
import 'blog_editor_page.dart';

class BlogFeedPage extends ConsumerWidget {
  final bool embedded;

  const BlogFeedPage({
    super.key,
    this.embedded = false,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final state = ref.watch(blogsProvider);

    Widget content = state.when(
      loading: () => const LoadingView(),

      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () {
          ref.read(blogsProvider.notifier).refreshBlogs();
        },
      ),

      data: (blogs) {
        return RefreshIndicator(
          onRefresh: () {
            return ref.read(blogsProvider.notifier).refreshBlogs();
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              22,
              14,
              22,
              100,
            ),
            itemCount: blogs.length,
            separatorBuilder: (_, index) {
              return const SizedBox(height: 14);
            },
            itemBuilder: (context, index) {
              return _BlogCard(
                blog: blogs[index],
              );
            },
          ),
        );
      },
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Latest stories',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BlogEditorPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),

      body: content,
    );
  }
}

class _BlogCard extends ConsumerWidget {
  final Blog blog;

  const _BlogCard({
    required this.blog,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentUser = ref.watch(authStateProvider).value;

    final isMine = currentUser?.id == blog.userId;
    return InkWell(
      borderRadius: BorderRadius.circular(24),

      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlogDetailPage(
              blog: blog,
            ),
          ),
        );
      },

      child: Card(
        clipBehavior: Clip.antiAlias,

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.img != null)
              SizedBox(
                height: 190,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl:
                      '${AppConstants.storageBaseUrl}${blog.img}',
                  fit: BoxFit.cover,

                  errorWidget: (
                    context,
                    url,
                    error,
                  ) {
                    return const ColoredBox(
                      color: Colors.black12,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 42,
                      ),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(18),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    blog.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    blog.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 15,
                        child: Text(
                          blog.authorName.isNotEmpty
                              ? blog.authorName[0].toUpperCase()
                              : 'U',
                        ),
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          blog.authorName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Only show edit/delete for the blog owner.
                      if (isMine) ...[
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlogEditorPage(
                                  id: blog.id,
                                  initialName: blog.name,
                                  initialDescription:
                                      blog.description,
                                  initialImage: blog.img,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                          ),
                        ),

                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () {
                            _confirmDelete(
                              context,
                              ref,
                              blog,
                            );
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                          ),
                        ),
                      ] else
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Blog blog,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete story?'),

          content: const Text(
            'This action cannot be undone.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(blogsProvider.notifier)
          .deleteBlog(blog.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story deleted'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    }
  }
}