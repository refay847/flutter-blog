import '../../domain/entities/comment.dart';

class CommentModel extends Comment {
  const CommentModel({
    required super.id,
    required super.userId,
    required super.blogId,
    required super.body,
    required super.userName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    return CommentModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      blogId: (json['blog_id'] as num).toInt(),
      body: json['body']?.toString() ?? '',
      userName: user is Map
          ? user['name']?.toString() ?? 'Unknown'
          : 'Unknown',
    );
  }
}