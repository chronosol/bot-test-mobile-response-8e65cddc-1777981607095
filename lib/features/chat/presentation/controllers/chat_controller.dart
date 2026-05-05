import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/message.dart';
import '../../data/chat_repository.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/websocket/websocket_service.dart';
import '../widgets/chat_input_bar.dart';

/// Parameters for ChatController family provider
class ChatControllerParams {
  final String chatbotId;
  final String? chatbotName;
  final String? businessName;

  const ChatControllerParams({
    required this.chatbotId,
    this.chatbotName,
    this.businessName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatControllerParams &&
          runtimeType == other.runtimeType &&
          chatbotId == other.chatbotId &&
          chatbotName == other.chatbotName &&
          businessName == other.businessName;

  @override
  int get hashCode =>
      chatbotId.hashCode ^
      chatbotName.hashCode ^
      businessName.hashCode;
}

class ChatController extends FamilyAsyncNotifier<ChatSession, ChatControllerParams> {
  late final ChatRepository _repo;
  late final String _sessionId;
  late final String _chatbotId;
  String? _chatId;
  String? _chatbotName;
  String? _businessName;
  String? _pendingUserMessageId;
  Timer? _wsTimeoutTimer;

  @override
  Future<ChatSession> build(ChatControllerParams params) async {
    _chatbotId = params.chatbotId;
    _chatbotName = params.chatbotName;
    _businessName = params.businessName;
    _repo      = ref.read(chatRepositoryProvider);
    _sessionId = const Uuid().v4();

    // Set up WebSocket response callback
    ref.read(webSocketServiceProvider).setChatResponseCallback(
          chatResponseCallback,
        );

    // Initialize chat asynchronously - don't block UI
    _initializeChatInBackground();

    // Generate dynamic welcome message using chatbot name and business name
    final botName = _chatbotName ?? AppConfig.botName;
    final businessName = _businessName ?? AppConfig.businessName;
    final welcomeMessage = "Hi there! 👋 I'm $botName, your personal assistant at $businessName. How can I help you today?";

    final session = ChatSession(
      id:        _sessionId,
      messages:  [ChatMessage.bot(welcomeMessage)],
      startedAt: DateTime.now(),
    );

    return session;
  }

  void cleanup() {
    _wsTimeoutTimer?.cancel();
    ref.read(webSocketServiceProvider).setChatResponseCallback(null);
  }

  /// Handle incoming WebSocket chat response
  void chatResponseCallback({
    required String chatId,
    required String chatbotId,
    required String reply,
  }) {
    final pendingId = _pendingUserMessageId;
    if (pendingId == null) return;

    _wsTimeoutTimer?.cancel();
    _pendingUserMessageId = null;

    final current = state.valueOrNull;
    if (current == null) return;

    final botReply = ChatMessage.bot(reply);
    final newMessages = current.messages
        .where((m) => m.type != MessageType.typing)
        .map((m) => m.id == pendingId ? m.copyWith(status: MessageStatus.read) : m)
        .toList()
      ..add(botReply);

    state = AsyncData(current.copyWith(
      messages: newMessages,
      isLoading: false,
    ));
  }

  void _initializeChatInBackground() {
    Future.microtask(() async {
      try {
        _chatId = await _repo.initializeChat();
      } catch (e) {
        // Silently fail - will retry when sending message
      }
    });
  }

  /// Get the chatId for this session
  String get chatId => _chatId ?? '';

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistically add user message + typing indicator
    final userMsg = ChatMessage.user(trimmed);
    final typing = ChatMessage.typing();

    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg, typing],
      isLoading: true,
    ));

    _pendingUserMessageId = userMsg.id;

    try {
      // Fire-and-forget HTTP request
      await _repo.sendMessage(
        sessionId: _sessionId,
        userMessage: trimmed,
        history: current.messages,
        chatbotId: _chatbotId,
      );

      // Start timeout - if WebSocket doesn't respond in 120s, show error
      _wsTimeoutTimer?.cancel();
      _wsTimeoutTimer = Timer(const Duration(seconds: 120), () {
        if (_pendingUserMessageId == userMsg.id) {
          _pendingUserMessageId = null;
          final updated = state.valueOrNull;
          if (updated == null) return;

          final withoutTyping = updated.messages
              .where((m) => m.type != MessageType.typing)
              .map((m) => m.id == userMsg.id ? m.copyWith(status: MessageStatus.failed) : m)
              .toList();

          state = AsyncData(updated.copyWith(
            messages: withoutTyping,
            isLoading: false,
            errorMessage: 'Response timed out — please try again.',
          ));
        }
      });
    } catch (e) {
      _pendingUserMessageId = null;
      _wsTimeoutTimer?.cancel();

      final updated = state.valueOrNull;
      if (updated == null) return;

      final withoutTyping = updated.messages
          .where((m) => m.type != MessageType.typing)
          .map((m) => m.id == userMsg.id ? m.copyWith(status: MessageStatus.failed) : m)
          .toList();

      state = AsyncData(updated.copyWith(
        messages: withoutTyping,
        isLoading: false,
        errorMessage: e is ChatException ? e.message : 'Failed to send message',
      ));
    }
  }

  Future<void> sendAttachment(ChatAttachment attachment) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final msgType = attachment.type == AttachmentType.image
        ? MessageType.image
        : attachment.type == AttachmentType.audio
            ? MessageType.audio
            : MessageType.file;

    final userMsg = ChatMessage.userWithAttachment(
      content: '',
      file: attachment.file,
      name: attachment.name,
      mimeType: attachment.mimeType,
      msgType: msgType,
    );

    final typing = ChatMessage.typing();

    state = AsyncData(current.copyWith(
      messages: [...current.messages, userMsg, typing],
      isLoading: true,
    ));

    _pendingUserMessageId = userMsg.id;

    try {
      await _repo.sendMessage(
        sessionId: _sessionId,
        userMessage: '[Attachment: ${attachment.name}]',
        history: current.messages,
        chatbotId: _chatbotId,
      );

      _wsTimeoutTimer?.cancel();
      _wsTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (_pendingUserMessageId == userMsg.id) {
          _pendingUserMessageId = null;
          final updated = state.valueOrNull;
          if (updated == null) return;

          final withoutTyping = updated.messages
              .where((m) => m.type != MessageType.typing)
              .map((m) => m.id == userMsg.id ? m.copyWith(status: MessageStatus.failed) : m)
              .toList();

          state = AsyncData(updated.copyWith(
            messages: withoutTyping,
            isLoading: false,
            errorMessage: 'Response timed out — please try again.',
          ));
        }
      });
    } catch (e) {
      _pendingUserMessageId = null;
      _wsTimeoutTimer?.cancel();

      final updated = state.valueOrNull;
      if (updated == null) return;

      final newMessages = updated.messages
          .where((m) => m.type != MessageType.typing)
          .map((m) => m.id == userMsg.id ? m.copyWith(status: MessageStatus.failed) : m)
          .toList();

      state = AsyncData(updated.copyWith(
        messages: newMessages,
        isLoading: false,
        errorMessage: e is ChatException ? e.message : 'Failed to send attachment',
      ));
    }
  }

  void clearError() {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(errorMessage: null));
  }

  void retryLastMessage() {
    final current = state.valueOrNull;
    if (current == null) return;

    final failed = current.messages.lastWhere(
      (m) => m.isUser && m.status == MessageStatus.failed,
      orElse: () => current.messages.last,
    );

    if (failed.isUser && failed.status == MessageStatus.failed) {
      final withoutFailed = current.messages.where((m) => m.id != failed.id).toList();
      state = AsyncData(current.copyWith(messages: withoutFailed));
      sendMessage(failed.content);
    }
  }
}

final chatControllerProvider =
    AsyncNotifierProvider.family<ChatController, ChatSession, ChatControllerParams>(ChatController.new);
