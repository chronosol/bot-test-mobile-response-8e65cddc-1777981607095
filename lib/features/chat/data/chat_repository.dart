import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/message.dart';
import '../../../core/constants/app_config.dart';

class ChatRepository {
  final Dio _dio;
  String? _chatId;
  bool _isInitialized = false;

  ChatRepository() : _dio = Dio(BaseOptions(
    baseUrl:        AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    headers: {
      'Content-Type':  'application/json',
      'X-API-Key':  AppConfig.apiKey,  // API key for mobile webhook authentication
    },
  )) {
    _dio.interceptors.add(LogInterceptor(responseBody: false));
  }

  /// Initialize chat - generate or load chatId
  /// Called when user first starts a chat
  Future<String> initializeChat() async {
    // If already initialized, return existing chatId
    if (_isInitialized && _chatId != null && _chatId!.isNotEmpty) {
      return _chatId!;
    }

    // Load existing chatId from storage
    final prefs = await SharedPreferences.getInstance();
    _chatId = prefs.getString('chat_id');

    // Generate new chatId if not exists
    if (_chatId == null || _chatId!.isEmpty) {
      _chatId = _generateNewChatId();
      await prefs.setString('chat_id', _chatId!);
    }

    // Optionally notify backend of new chat session
    try {
      final chatbotId = AppConfig.chatbotId.isNotEmpty 
          ? AppConfig.chatbotId 
          : AppConfig.organisationId;
      
      await _dio.post(
        '/chatbots/mobile/$chatbotId/init',
        data: {
          'chatId': _chatId,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      // Continue even if backend init fails - local chatId still valid
    }

    _isInitialized = true;
    return _chatId!;
  }

  /// Generate a new unique chatId
  String _generateNewChatId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    return 'chat_${timestamp}_$random';
  }

  /// Save chatId to local storage
  Future<void> _saveChatId(String id) async {
    _chatId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_id', id);
  }

  /// Get or generate chatId
  Future<String> getChatId() async {
    // Use initialized chatId if available
    if (_chatId != null && _chatId!.isNotEmpty) {
      return _chatId!;
    }

    // Load from storage
    final prefs = await SharedPreferences.getInstance();
    _chatId = prefs.getString('chat_id');

    if (_chatId != null && _chatId!.isNotEmpty) {
      return _chatId!;
    }

    // Generate new chatId
    return initializeChat();
  }

  /// Check if chat is initialized
  bool get isChatInitialized => _isInitialized;

  /// Send a message (fire-and-forget). Response arrives via WebSocket.
  Future<void> sendMessage({
    required String sessionId,
    required String userMessage,
    required List<ChatMessage> history,
    required String chatbotId,
  }) async {
    // Ensure we have a chatId
    final chatId = await getChatId();

    // If chatbotId is empty, use organisationId as fallback
    final botId = chatbotId.isNotEmpty ? chatbotId : AppConfig.organisationId;

    try {
      // Build the endpoint with chatbotId
      final endpoint = AppConfig.chatEndpoint.replaceAll(':chatbotId', botId);

      final response = await _dio.post(
        endpoint,
        data: {
          'message':    userMessage,
          'chatId':   chatId,
          'chatbotId': botId,
        },
      );

      // If response contains a new chatId, save it
      final data = response.data as Map<String, dynamic>;
      if (data['chatId'] != null && _chatId == null) {
        await _saveChatId(data['chatId'] as String);
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) throw ChatException('Too many requests — please wait a moment.');
      if (status != null && status >= 500) throw ChatException('Server error — please try again.');
      if (e.type == DioExceptionType.connectionTimeout) throw ChatException('Connection timed out — check your internet.');
      throw ChatException('Could not reach the assistant: ${e.message}');
    } catch (e) {
      throw ChatException('Unexpected error: $e');
    }
  }
}

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);
  @override
  String toString() => message;
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());
