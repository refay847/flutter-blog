import '../../domain/entities/blog.dart';
import '../../domain/entities/comment.dart';
import 'comment_model.dart';

class BlogModel extends Blog {
  const BlogModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.description,
    required super.img,
    required super.authorName,
    super.likesCount,
    super.commentsCount,
    super.isLiked,
    super.comments,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    final commentsJson = json['comments'];

    final comments = commentsJson is List
        ? commentsJson
            .whereType<Map>()
            .map(
              (item) => CommentModel.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : <CommentModel>[];

    return BlogModel(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      img: json['img']?.toString(),
      authorName: user is Map
          ? user['name']?.toString() ?? 'Unknown'
          : 'Unknown',
      likesCount: _intValue(json['likes_count'] ?? json['likesCount']),
      commentsCount: _intValue(json['comments_count'] ?? json['commentsCount']),
      isLiked: _boolValue(json['is_liked'] ?? json['isLiked'] ?? json['liked']),
      comments: comments,
    );
  }

  /// Round-trips back into the same shape `fromJson` expects, so the same
  /// parser works for both API responses and the local cache.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'img': img,
      'user': {'name': authorName},
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'comments': comments.map(_commentToJson).toList(),
    };
  }

  static Map<String, dynamic> _commentToJson(Comment comment) {
    if (comment is CommentModel) return comment.toJson();

    return CommentModel(
      id: comment.id,
      userId: comment.userId,
      blogId: comment.blogId,
      body: comment.body,
      userName: comment.userName,
    ).toJson();
  }

  static int _intValue(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static bool _boolValue(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    return false;
  }
}