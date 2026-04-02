import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'auth/login_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Auth state is already resolved via AuthProvider._initAuth() in the constructor.
    // We just needed to wait for the splash animation.

    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, __) => const MainShell(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, __) => const LoginScreen(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: settings.logo(size: 80, applyTheme: false),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 600.ms),

            const SizedBox(height: 32),

            // App Name
            Text(
              'AiDea',
              style: AppTheme.headline2(
                color: isDark
                    ? AppTheme.darkTextPrimary
                    : AppTheme.lightTextPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.2, duration: 500.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Your intelligence, distilled.',
              style: AppTheme.bodyLarge(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

            const Spacer(flex: 2),

            // Divider
            Container(
              width: 200,
              height: 1,
              color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
            ).animate().fadeIn(delay: 800.ms).scaleX(
                  begin: 0,
                  end: 1,
                  duration: 600.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: 16),

            // Status
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'SYSTEMS ACTIVE',
                  style: AppTheme.labelSmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary.withValues(alpha: 0.6)
                        : AppTheme.lightTextSecondary.withValues(alpha: 0.6),
                  ).copyWith(letterSpacing: 3),
                ),
              ],
            ).animate().fadeIn(delay: 1000.ms, duration: 500.ms),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}
