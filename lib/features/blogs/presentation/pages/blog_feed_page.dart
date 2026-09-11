import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          ref
              .read(blogsProvider.notifier)
              .refreshBlogs();
        },
      ),
      data: (blogs) {
        return RefreshIndicator(
          onRefresh: () {
            return ref
                .read(blogsProvider.notifier)
                .refreshBlogs();
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BlogEditorPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Write'),
      ),
      body: content,
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Blog blog;

  const _BlogCard({
    required this.blog,
  });

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment:
              CrossAxisAlignment.start,
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
                crossAxisAlignment:
                    CrossAxisAlignment.start,
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
                              ? blog.authorName[0]
                                  .toUpperCase()
                              : 'U',
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        blog.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const Spacer(),

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
}