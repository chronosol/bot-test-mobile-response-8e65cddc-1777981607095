import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_config.dart';

class QuickReplies extends StatelessWidget {
  final void Function(String) onTap;

  const QuickReplies({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection:  Axis.horizontal,
        padding:          const EdgeInsets.symmetric(horizontal: 16),
        itemCount:        AppConfig.quickReplies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final label = AppConfig.quickReplies[i];
          return _Chip(
            label: label,
            onTap: () => onTap(label),
            delay: i * 60,
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final int delay;

  const _Chip({required this.label, required this.onTap, required this.delay});

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color:        primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(21),
          border:       Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:       primary,
            fontSize:    13,
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.1,
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
    .slideX(begin: 0.2, end: 0, delay: Duration(milliseconds: delay), duration: 300.ms, curve: Curves.easeOut);
  }
}
