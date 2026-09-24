

class Comment {
  final int? id;
  final int questionId;
  final int userId;
  final int? parentId;
  final String content;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool isHidden;
  final String? userNome;
  final String? userFoto;
  final int likesCount;
  final int repliesCount;
  final List<Comment>? replies;

  Comment({
    this.id,
    required this.questionId,
    required this.userId,
    this.parentId,
    required this.content,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.isHidden = false,
    this.userNome,
    this.userFoto,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.replies,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      questionId: json['question_id'],
      userId: json['user_id'],
      parentId: json['parent_id'],
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : null,
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
      deletedAt: json['deleted_at'] != null 
        ? DateTime.parse(json['deleted_at']) 
        : null,
      isHidden: json['is_hidden'] ?? false,
      userNome: json['user_nome'],
      userFoto: json['user_foto'],
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      replies: json['replies'] != null
        ? (json['replies'] as List)
            .map((r) => Comment.fromJson(r))
            .toList()
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_id': questionId,
      'user_id': userId,
      'parent_id': parentId,
      'content': content,
    };
  }
}

