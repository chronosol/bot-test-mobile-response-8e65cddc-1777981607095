import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_config.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D0D14) : const Color(0xFFF5F5FA);
    final cardColor = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE8E8F0);

    final contactMethods = _getContactMethods();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Contact Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.headset_mic_rounded,
                      color: AppTheme.accent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Need Help?',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Our support team is here to assist you',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 24),
            
            Text(
              'Choose a contact method',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            
            const SizedBox(height: 12),
            
            ...contactMethods.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ContactMethodTile(
                  method: entry.value,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  index: entry.key,
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Average response time: Within 24 hours',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF25D366),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  List<_ContactMethod> _getContactMethods() {
    final methods = <_ContactMethod>[];
    
    if (AppConfig.whatsappNumber.isNotEmpty) {
      methods.add(_ContactMethod(
        icon: Icons.chat_rounded,
        title: 'WhatsApp',
        subtitle: 'Chat with us on WhatsApp',
        color: const Color(0xFF25D366),
        action: () => _launchUrl('https://wa.me/${AppConfig.whatsappNumber.replaceAll(RegExp(r'[^\d]'), '')}'),
      ));
    }
    
    if (AppConfig.telegramHandle.isNotEmpty) {
      methods.add(_ContactMethod(
        icon: Icons.send_rounded,
        title: 'Telegram',
        subtitle: 'Reach us on Telegram',
        color: const Color(0xFF0088CC),
        action: () => _launchUrl('https://t.me/${AppConfig.telegramHandle.replaceAll('@', '')}'),
      ));
    }
    
    if (AppConfig.supportEmail.isNotEmpty) {
      methods.add(_ContactMethod(
        icon: Icons.email_rounded,
        title: 'Email Support',
        subtitle: 'Send us an email',
        color: AppTheme.primary,
        action: () => _launchUrl('mailto:${AppConfig.supportEmail}?subject=Support Request'),
      ));
    }
    
    methods.add(_ContactMethod(
      icon: Icons.phone_rounded,
      title: 'Call Us',
      subtitle: AppConfig.whatsappNumber.isNotEmpty ? 'Call our support line' : 'Call for assistance',
      color: const Color(0xFFFF5722),
      action: () {
        if (AppConfig.whatsappNumber.isNotEmpty) {
          _launchUrl('tel:${AppConfig.whatsappNumber}');
        }
      },
    ));
    
    return methods;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactMethod {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback action;

  _ContactMethod({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.action,
  });
}

class _ContactMethodTile extends StatelessWidget {
  final _ContactMethod method;
  final Color cardColor;
  final Color borderColor;
  final int index;

  const _ContactMethodTile({
    required this.method,
    required this.cardColor,
    required this.borderColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: method.action,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: method.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                method.icon,
                color: method.color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 50), duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}