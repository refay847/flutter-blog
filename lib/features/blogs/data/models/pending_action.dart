// lib/features/blog/data/models/pending_action.dart
enum PendingActionType { like, unlike, addComment }

class PendingAction {
  final String id;
  final PendingActionType type;
  final int blogId;
  final String? commentBody;
  final DateTime createdAt;

  PendingAction({
    required this.id,
    required this.type,
    required this.blogId,
    this.commentBody,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'blogId': blogId,
        'commentBody': commentBody,
        'createdAt': createdAt.toIso8601String(),
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
        id: json['id'] as String,
        type: PendingActionType.values.byName(json['type'] as String),
        blogId: json['blogId'] as int,
        commentBody: json['commentBody'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}