import 'dart:io';
import 'package:uuid/uuid.dart';

enum MessageRole { user, bot, system }
enum MessageStatus { sending, sent, delivered, read, failed }
enum MessageType { text, image, file, audio, quickReply, typing }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final MessageStatus status;
  final MessageType type;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? attachmentName;
  final File? attachmentFile;
  final String? attachmentMimeType;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    this.status = MessageStatus.sent,
    this.type = MessageType.text,
    required this.timestamp,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentFile,
    this.attachmentMimeType,
  });

  bool get isBot => role == MessageRole.bot;
  bool get isUser => role == MessageRole.user;
  bool get hasAttachment => attachmentUrl != null || attachmentFile != null;

  static ChatMessage user(String text) => ChatMessage(
    id: const Uuid().v4(),
    content: text,
    role: MessageRole.user,
    status: MessageStatus.sending,
    timestamp: DateTime.now(),
  );

  static ChatMessage userWithAttachment({
    required String content,
    required File file,
    required String name,
    String? mimeType,
    MessageType msgType = MessageType.image,
  }) => ChatMessage(
    id: const Uuid().v4(),
    content: content,
    role: MessageRole.user,
    status: MessageStatus.sending,
    type: msgType,
    timestamp: DateTime.now(),
    attachmentFile: file,
    attachmentName: name,
    attachmentMimeType: mimeType,
  );

  static ChatMessage bot(String text) => ChatMessage(
    id: const Uuid().v4(),
    content: text,
    role: MessageRole.bot,
    status: MessageStatus.delivered,
    timestamp: DateTime.now(),
  );

  static ChatMessage typing() => ChatMessage(
    id: 'typing',
    content: '',
    role: MessageRole.bot,
    type: MessageType.typing,
    timestamp: DateTime.now(),
  );

  ChatMessage copyWith({MessageStatus? status}) => ChatMessage(
    id: id,
    content: content,
    role: role,
    status: status ?? this.status,
    type: type,
    timestamp: timestamp,
    attachmentUrl: attachmentUrl,
    attachmentName: attachmentName,
    attachmentFile: attachmentFile,
    attachmentMimeType: attachmentMimeType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatMessage && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ChatSession {
  final String          id;
  final List<ChatMessage> messages;
  final DateTime        startedAt;
  final bool            isLoading;
  final String?         errorMessage;

  const ChatSession({
    required this.id,
    this.messages    = const [],
    required this.startedAt,
    this.isLoading   = false,
    this.errorMessage,
  });

  ChatSession copyWith({
    List<ChatMessage>? messages,
    bool?  isLoading,
    String? errorMessage,
  }) => ChatSession(
    id:           id,
    messages:     messages     ?? this.messages,
    startedAt:    startedAt,
    isLoading:    isLoading    ?? this.isLoading,
    errorMessage: errorMessage,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ChatSession && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
