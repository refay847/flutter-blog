import '../../domain/entities/blog.dart';

class BlogModel extends Blog {
  const BlogModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.img,
    required super.authorName,
  });

  factory BlogModel.fromJson(Map<String, dynamic> j) {
    final user = j['user'];

    return BlogModel(
      id: (j['id'] as num).toInt(),
      userId: (j['user_id'] as num).toInt(),
      name: j['name']?.toString() ?? '',
      description: j['description']?.toString() ?? '',
      img: j['img']?.toString(),
      authorName: user is Map
          ? user['name']?.toString() ?? 'Unknown'
          : 'Unknown',
    );
  }
}