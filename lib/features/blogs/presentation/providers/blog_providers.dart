import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/blog_remote_data_source.dart';
import '../../data/repositories/blog_repository_impl.dart';
import '../../domain/entities/blog.dart';
import '../../domain/repositories/blog_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final blogRepositoryProvider = Provider<BlogRepository>(
  (ref) => BlogRepositoryImpl(
    BlogRemoteDataSource(
      ref.watch(apiClientProvider),
    ),
  ),
);

final blogsProvider =
    AsyncNotifierProvider<BlogsNotifier, List<Blog>>(
  BlogsNotifier.new,
);

class BlogsNotifier extends AsyncNotifier<List<Blog>> {
  @override
  Future<List<Blog>> build() {
    return ref.watch(blogRepositoryProvider).all();
  }

  Future<void> refreshBlogs() async {
    state = await AsyncValue.guard(
      () => ref.read(blogRepositoryProvider).all(),
    );
  }

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
      ...(state.value ?? []),
    ]);
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

    state = AsyncData(
      (state.value ?? [])
          .map(
            (item) => item.id == id ? blog : item,
          )
          .toList(),
    );
  }

  Future<void> deleteBlog(int id) async {
    await ref.read(blogRepositoryProvider).delete(id);

    state = AsyncData(
      (state.value ?? [])
          .where((item) => item.id != id)
          .toList(),
    );
  }
}