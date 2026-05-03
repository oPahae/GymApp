enum MessageType { text, image, audio, video }
enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final String time;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? mediaUrl;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.mediaUrl,
  });

  factory ChatMessage.fromUser({
    required String id,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: id,
      text: text,
      isUser: true,
      time: _formatTime(now),
      timestamp: now,
      type: type,
      status: MessageStatus.sending,
      mediaUrl: mediaUrl,
    );
  }

  /// Message envoyé par le coach humain
  factory ChatMessage.fromCoach({
    required String id,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: id,
      text: text,
      isUser: false,
      time: _formatTime(now),
      timestamp: now,
      type: type,
      status: MessageStatus.delivered,
      mediaUrl: mediaUrl,
    );
  }

  ChatMessage copyWith({
    String? text,
    MessageStatus? status,
    String? mediaUrl,
  }) {
    return ChatMessage(
      id: id,
      text: text ?? this.text,
      isUser: isUser,
      time: time,
      timestamp: timestamp,
      type: type,
      status: status ?? this.status,
      mediaUrl: mediaUrl ?? this.mediaUrl,
    );
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}