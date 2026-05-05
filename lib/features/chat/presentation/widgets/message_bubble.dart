import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/message.dart';
import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool        showAvatar;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.typing) return _TypingBubble(showAvatar: showAvatar);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isBot) ...[
            _Avatar(visible: showAvatar),
            const SizedBox(width: 8),
          ],
          Flexible(child: _Bubble(message: message, onRetry: onRetry)),
          if (message.isUser) ...[
            const SizedBox(width: 4),
            _StatusIcon(status: message.status),
          ],
        ],
      ),
    )
    .animate()
    .fadeIn(duration: 200.ms)
    .slideY(begin: 0.15, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}

class _Avatar extends StatelessWidget {
  final bool visible;
  const _Avatar({required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox(width: 32);
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
          begin:  Alignment.topLeft,
          end:    Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;
  const _Bubble({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBot = !message.isUser;  // Fixed: true when message is from bot
    final primary = AppTheme.primary;
    final failed = message.status == MessageStatus.failed;

    final bgColor = isBot
        ? primary
        : (isDark ? const Color(0xFF1E1E2A) : Colors.white);

    final textColor = isBot
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isBot ? 20 : 4),
      bottomRight: Radius.circular(isBot ? 4 : 20),
    );

    return Column(
      crossAxisAlignment: isBot ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: !isBot
                ? Border.all(
                    color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE8E8F0),
                    width: 1,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.hasAttachment) _buildAttachment(context, isBot),
              if (message.content.isNotEmpty)
                isBot
                    ? MarkdownBody(
                        data: message.content,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                          strong: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                          em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
                          code: TextStyle(
                            color: primary,
                            backgroundColor: primary.withValues(alpha: 0.1),
                            fontFamily: 'monospace',
                            fontSize: 13,
                          ),
                          a: TextStyle(color: primary, decoration: TextDecoration.underline),
                        ),
                        onTapLink: (text, href, title) {
                          if (href != null) launchUrl(Uri.parse(href));
                        },
                      )
                    : Text(
                        message.content,
                        style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
                      ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('h:mm a').format(message.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
            if (failed) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onRetry,
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 13, color: AppTheme.accent),
                    const SizedBox(width: 2),
                    Text('Retry', style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildAttachment(BuildContext context, bool isUser) {
    if (message.type == MessageType.image && message.attachmentFile != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            message.attachmentFile!,
            width: 200,
            height: 150,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 200,
              height: 150,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image_rounded, size: 40),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser
            ? Colors.white.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAttachmentIcon(),
            size: 24,
            color: isUser ? Colors.white : AppTheme.primary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.attachmentName ?? 'Attachment',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isUser ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _getFileSize(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser
                        ? Colors.white.withValues(alpha: 0.7)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAttachmentIcon() {
    switch (message.type) {
      case MessageType.image:
        return Icons.image_rounded;
      case MessageType.audio:
        return Icons.audiotrack_rounded;
      case MessageType.file:
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  String _getFileSize() {
    return 'File';
  }
}

class _StatusIcon extends StatelessWidget {
  final MessageStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        );
      case MessageStatus.sent:
        return Icon(Icons.check_rounded, size: 14, color: Colors.grey.shade400);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 14, color: Colors.grey.shade400);
      case MessageStatus.read:
        return Icon(Icons.done_all_rounded, size: 14, color: AppTheme.primary);
      case MessageStatus.failed:
        return Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.accent);
    }
  }
}

class _TypingBubble extends StatelessWidget {
  final bool showAvatar;
  const _TypingBubble({required this.showAvatar});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(visible: showAvatar),
          const SizedBox(width: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color:        isDark ? const Color(0xFF1E1E2A) : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft:     Radius.circular(20),
                topRight:    Radius.circular(20),
                bottomRight: Radius.circular(20),
                bottomLeft:  Radius.circular(4),
              ),
              border: Border.all(
                color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE8E8F0),
              ),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    )
    .animate(onPlay: (c) => c.repeat())
    .fadeIn(duration: 200.ms);
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final delay = i * 0.2;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t  = ((_ctrl.value - delay).clamp(0.0, 1.0));
            final y  = -4.0 * (1 - (t * 2 - 1).abs());
            return Transform.translate(
              offset: Offset(0, y),
              child:  Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child:   CircleAvatar(
                  radius: 4,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
