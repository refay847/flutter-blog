import 'comment.dart';

class Blog {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String? img;
  final String authorName;

  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  final List<Comment> comments;

  const Blog({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.img,
    required this.authorName,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.comments = const [],
  });

  Blog copyWith({
    int? likesCount,
    int? commentsCount,
    bool? isLiked,
    List<Comment>? comments,
  }) {
    return Blog(
      id: id,
      userId: userId,
      name: name,
      description: description,
      img: img,
      authorName: authorName,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
    );
  }
}