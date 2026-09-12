class Comment {
  final int id;
  final int userId;
  final int blogId;
  final String body;
  final String userName;

  const Comment({
    required this.id,
    required this.userId,
    required this.blogId,
    required this.body,
    required this.userName,
  });
}