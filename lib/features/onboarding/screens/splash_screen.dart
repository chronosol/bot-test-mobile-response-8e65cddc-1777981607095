import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        final chatId = AppConfig.chatbotId.isNotEmpty 
            ? AppConfig.chatbotId 
            : 'default';
        context.go('/chat/$chatId');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center:  Alignment.center,
                radius:  1.4,
                colors:  [
                  AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Grid texture
          CustomPaint(painter: _GridPainter(color: AppTheme.primary.withValues(alpha: 0.04))),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primary, AppTheme.accent],
                      begin:  Alignment.topLeft,
                      end:    Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color:      AppTheme.primary.withValues(alpha: 0.4),
                        blurRadius: 32,
                        offset:     const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size:  44,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.6, 0.6), duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 28),

                // Business name
                Text(
                  AppConfig.businessName,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    letterSpacing: -1.5,
                  ),
                )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.3, end: 0, delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  AppConfig.tagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),

                const SizedBox(height: 56),

                // Bot intro
                Container(
                  margin:  const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color:        isDark ? const Color(0xFF1E1E2A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:       Border.all(
                      color: isDark ? const Color(0xFF2A2A3C) : const Color(0xFFE8E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
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
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppConfig.botName, style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              AppConfig.botRole,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:        const Color(0xFF2ECC71).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Online',
                          style: TextStyle(
                            color:      Color(0xFF2ECC71),
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0, delay: 700.ms),
              ],
            ),
          ),

          // Loading indicator at bottom
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Center(
              child: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color:       AppTheme.primary.withValues(alpha: 0.5),
                ),
              )
              .animate()
              .fadeIn(delay: 1200.ms, duration: 400.ms),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1;
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
