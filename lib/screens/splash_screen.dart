import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Elegant delay for the splash experience
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) =>
              authProvider.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background identity color
          Positioned.fill(
            child: Container(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
            ),
          ),

          // Subtle accent glow
          Positioned(
            top: -150,
            right: -150,
            child:
                Container(
                      width: 400,
                      height: 400,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: settings.accentColor.withOpacity(0.15),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 4.seconds,
                      begin: const Offset(1, 1),
                      end: const Offset(1.2, 1.2),
                    )
                    .blur(
                      begin: const Offset(80, 80),
                      end: const Offset(120, 120),
                    ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Premium Logo Presentation
                settings
                    .glassMorphicContainer(
                      context: context,
                      padding: const EdgeInsets.all(32),
                      opacity: isDark ? 0.05 : 0.4,
                      blur: 30,
                      borderRadius: BorderRadius.circular(40),
                      child: settings
                          .logo(size: 140, applyTheme: false)
                          .animate()
                          .scale(duration: 800.ms, curve: Curves.easeOutBack)
                          .shimmer(delay: 1.seconds, duration: 2.seconds),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1),

                const SizedBox(height: 40),

                // Branded Title
                Text(
                  'AIdea',
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 2,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),

                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Intelligent Video Insights',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: settings.accentColor.withOpacity(0.8),
                    letterSpacing: 1.5,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 80),

                // Minimalist Progress
                SizedBox(
                  width: 160,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      backgroundColor: settings.accentColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        settings.accentColor,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 1.seconds),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
