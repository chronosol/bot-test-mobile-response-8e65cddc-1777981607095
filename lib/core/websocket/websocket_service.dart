library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/app_config.dart';

typedef ChatResponseCallback = void Function({
  required String chatId,
  required String chatbotId,
  required String reply,
});

class WebSocketService {
  io.Socket? _socket;
  bool _isConnected = false;
  String? _currentChatId;
  ChatResponseCallback? _onChatResponse;

  bool get isConnected => _isConnected;

  void setChatResponseCallback(ChatResponseCallback? callback) {
    _onChatResponse = callback;
  }

  Future<void> connect(String chatId) async {
    if (_socket != null && _isConnected && _currentChatId == chatId) return;

    disconnect();

    _currentChatId = chatId;

    final botCreatorUrl = AppConfig.botCreatorUrl;

    final baseUrl = botCreatorUrl.replaceAll(RegExp(r'/$'), '');

    _socket = io.io(
      '$baseUrl/ws', // Connect to Socket.IO namespace
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setQuery({'userId': chatId})
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      _socket!.emit('subscribe', {'userId': chatId});
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
    });

    _socket!.on('chat:response', (data) {
      debugPrint('Received WebSocket message: $data');

      if (data is Map && _onChatResponse != null) {
        final chatId = data['chatId'] as String? ?? '';
        final chatbotId = data['chatbotId'] as String? ?? '';
        final reply = data['reply'] as String? ?? '';
        if (reply.isNotEmpty) {
          _onChatResponse!(
            chatId: chatId,
            chatbotId: chatbotId,
            reply: reply,
          );
        }
      }
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _currentChatId = null;
  }
}

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(() => service.disconnect());
  return service;
});
