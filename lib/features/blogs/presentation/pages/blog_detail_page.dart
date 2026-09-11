import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/blog.dart';

class BlogDetailPage extends StatelessWidget {
  final Blog blog;

  const BlogDetailPage({
    super.key,
    required this.blog,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

                Text(
                  blog.authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}