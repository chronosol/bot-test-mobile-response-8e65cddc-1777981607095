import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../controllers/chat_controller.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/quick_replies.dart';
import '../../domain/message.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_config.dart';
import '../../../../core/websocket/websocket_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatbotId;
  final String? chatId;
  final String? chatbotName;
  final String? businessName;

  const ChatScreen({
    super.key,
    required this.chatbotId,
    this.chatId,
    this.chatbotName,
    this.businessName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();
  bool _showQuickReplies   = true;

  @override
  void initState() {
    super.initState();
    // Connect WebSocket after chatId is available
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    // Wait briefly for chatId to be initialized
    await Future.delayed(const Duration(milliseconds: 500));
    final controller = ref.read(chatControllerProvider(_params));
    final chatId = controller.valueOrNull != null
        ? ref.read(chatControllerProvider(_params).notifier).chatId
        : null;
    if (chatId != null && chatId.isNotEmpty) {
      ref.read(webSocketServiceProvider).connect(chatId);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      if (animated) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: 300.ms,
          curve:    Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  ChatControllerParams get _params => ChatControllerParams(
        chatbotId: widget.chatbotId,
        chatbotName: widget.chatbotName,
        businessName: widget.businessName,
      );

  void _send(String text) {
    if (_showQuickReplies) setState(() => _showQuickReplies = false);
    ref.read(chatControllerProvider(_params).notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _handleAttachment(ChatAttachment attachment) {
    if (_showQuickReplies) setState(() => _showQuickReplies = false);
    ref.read(chatControllerProvider(_params).notifier).sendAttachment(attachment);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(chatControllerProvider(_params));

    ref.listen(chatControllerProvider(_params), (prev, next) {
      final prevCount = prev?.valueOrNull?.messages.length ?? 0;
      final nextCount = next.valueOrNull?.messages.length ?? 0;
      if (nextCount > prevCount) _scrollToBottom();
    });

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Error banner
          session.whenOrNull(
            data: (s) => s.errorMessage != null ? _ErrorBanner(
              message: s.errorMessage!,
              onRetry: () => ref.read(chatControllerProvider(_params).notifier).retryLastMessage(),
              onDismiss: () => ref.read(chatControllerProvider(_params).notifier).clearError(),
            ) : null,
          ) ?? const SizedBox.shrink(),

          // Message list
          Expanded(
            child: session.when(
              loading: () => const _LoadingState(),
              error:   (e, _) => _ErrorState(error: e.toString()),
              data:    (s) => _MessageList(
                session:        s,
                controller:     _scrollController,
              ),
            ),
          ),

          // Quick replies
          if (_showQuickReplies)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: QuickReplies(onTap: _send),
            ),

          // Input bar
          ChatInputBar(
            onSend:    _send,
            onAttach: _handleAttachment,
            isLoading: session.valueOrNull?.isLoading ?? false,
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      leading: _AppBarAction(icon: Icons.arrow_back_rounded, onTap: () => _navigateBack(context)),
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Bot avatar with online indicator
            Stack(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 11, height: 11,
                    decoration: BoxDecoration(
                      color:  const Color(0xFF2ECC71),
                      shape:  BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF16161F) : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // Name + status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatbotName ?? widget.businessName ?? AppConfig.botName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  ),
                  Text(
                    '${widget.businessName ?? AppConfig.businessName} · Online',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2ECC71),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            _AppBarAction(icon: Icons.search_rounded, onTap: () {}),
            const SizedBox(width: 4),
            _AppBarAction(icon: Icons.more_vert_rounded, onTap: () => _showOptions(context)),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context:       context,
      shape:         const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _OptionsSheet(),
    );
  }

  void _navigateBack(BuildContext context) {
    context.go('/');
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  final ChatSession session;
  final ScrollController controller;

  const _MessageList({required this.session, required this.controller});

  @override
  Widget build(BuildContext context) {
    final messages = session.messages;

    return ListView.builder(
      controller:   controller,
      padding:      const EdgeInsets.only(top: 12, bottom: 4),
      itemCount:    messages.length,
      itemBuilder:  (ctx, i) {
        final msg  = messages[i];
        // Show avatar only on the last consecutive bot message
        final isLastBot = msg.isBot &&
            (i == messages.length -1 || !messages[i + 1].isBot);

        return MessageBubble(
          key:        ValueKey(msg.id),
          message:    msg,
          showAvatar: isLastBot,
        );
      },
    );
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _AppBarAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon:     Icon(icon, size: 22),
      onPressed: onTap,
      padding:  EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  const _ErrorBanner({required this.message, required this.onRetry, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color:   AppTheme.accent.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.accent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: AppTheme.accent, fontSize: 13)),
          ),
          TextButton(onPressed: onRetry,   child: const Text('Retry')),
          IconButton(onPressed: onDismiss, icon: const Icon(Icons.close_rounded, size: 18)),
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 200.ms)
    .slideY(begin: -0.5, end: 0, duration: 200.ms);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
  );
}

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child:   Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 48, color: AppTheme.accent),
          const SizedBox(height: 16),
          Text('Could not connect', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet();

  @override
  Widget build(BuildContext context) {
    void handleNavigation(String route) {
      Navigator.pop(context);
      context.push(route);
    }

    final options = [
      (Icons.person_outline_rounded,    'View Business Profile', () => handleNavigation('profile')),
      (Icons.history_rounded,           'Chat History', () => handleNavigation('history')),
      (Icons.star_outline_rounded,      'Rate this Assistant', () => handleNavigation('rate')),
      (Icons.phone_outlined,            'Contact Human Support', () => handleNavigation('support')),
      (Icons.delete_outline_rounded,    'Clear Conversation', () => Navigator.pop(context)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40, height: 4,
          decoration: BoxDecoration(
            color:        Colors.grey.shade400,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Text(AppConfig.businessName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...options.map((o) => ListTile(
          leading:  Icon(o.$1, color: AppTheme.primary),
          title:    Text(o.$2),
          onTap:    o.$3,
        )),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }
}
