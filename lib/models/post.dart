class Comment {
  final String id;
  final String postId;
  final String content;
  final String nickname;
  final String replyTargetNickname;
  final String? parentCommentId;
  int likeCount;
  bool isLiked;

  Comment({
    required this.id,
    required this.postId,
    required this.content,
    required this.nickname,
    required this.replyTargetNickname,
    this.parentCommentId,
    this.likeCount = 0,
    this.isLiked = false,
  });
}

class Post {
  final String id;
  final String content;
  final String category;
  final String type;
  final String nickname;
  final DateTime createdAt;
  final String? backgroundImagePath;
  final List<Comment> comments;
  int likeCount;
  bool isLiked;
  int unreadCommentCount;

  Post({
    required this.id,
    required this.content,
    required this.category,
    required this.type,
    required this.nickname,
    required this.createdAt,
    this.backgroundImagePath,
    List<Comment>? comments,
    this.likeCount = 0,
    this.isLiked = false,
    this.unreadCommentCount = 0,
  }) : comments = comments ?? [];
}