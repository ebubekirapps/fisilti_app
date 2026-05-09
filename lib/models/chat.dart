class ChatRequest {
  final String id;
  final String fromUser;
  final String toUser;
  final String relatedPostId;
  final DateTime createdAt;
  bool accepted;
  bool rejected;

  ChatRequest({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.relatedPostId,
    required this.createdAt,
    this.accepted = false,
    this.rejected = false,
  });
}

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });
}

class ChatThread {
  final String id;
  String otherUser;
  final String relatedPostId;
  final List<ChatMessage> messages;
  DateTime updatedAt;
  int unreadCount;

  ChatThread({
    required this.id,
    required this.otherUser,
    required this.relatedPostId,
    required this.messages,
    required this.updatedAt,
    this.unreadCount = 0,
  });

  String get lastMessage =>
      messages.isEmpty ? "Henüz mesaj yok." : messages.last.text;
}