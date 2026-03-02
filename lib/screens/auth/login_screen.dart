import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import 'signup_screen.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Login failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Parallax/Animate
          Positioned.fill(
            child:
                Image.asset('assets/images/premium_bg.png', fit: BoxFit.cover)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .move(
                      begin: const Offset(-20, -20),
                      end: const Offset(20, 20),
                      duration: 20.seconds,
                      curve: Curves.easeInOut,
                    ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(isDark ? 0.8 : 0.4),
                    Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: settings.glassMorphicContainer(
                    context: context,
                    padding: const EdgeInsets.all(32),
                    opacity: isDark ? 0.1 : 0.7,
                    blur: 20,
                    borderRadius: BorderRadius.circular(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // App Logo Animated
                        Center(
                          child: settings
                              .logo(size: 120)
                              .animate()
                              .scale(
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              )
                              .shimmer(delay: 1.seconds, duration: 2.seconds),
                        ),
                        const SizedBox(height: 32),

                        // Welcome Text
                        Text(
                          'AIdea',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                          'Brilliant notes from any video.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 400.ms),
                        const SizedBox(height: 48),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            prefixIcon: Icon(
                              FontAwesomeIcons.envelope,
                              size: 18,
                              color: settings.accentColor,
                            ),
                            filled: true,
                            fillColor: (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter your email';
                            if (!value.contains('@'))
                              return 'Enter a valid email';
                            return null;
                          },
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                            prefixIcon: Icon(
                              FontAwesomeIcons.lock,
                              size: 18,
                              color: settings.accentColor,
                            ),
                            suffixIcon: IconButton(
                              icon: FaIcon(
                                _obscurePassword
                                    ? FontAwesomeIcons.eyeSlash
                                    : FontAwesomeIcons.eye,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            filled: true,
                            fillColor: (isDark ? Colors.black : Colors.white)
                                .withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter your password';
                            return null;
                          },
                        ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
                        const SizedBox(height: 32),

                        // Login Button
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [
                                    settings.accentColor,
                                    settings.accentColor.withBlue(255),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: settings.accentColor.withOpacity(
                                      0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: auth.isLoading ? null : _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Text(
                                        'SIGN IN',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            );
                          },
                        ).animate().fadeIn(delay: 800.ms).scale(),

                        const SizedBox(height: 24),

                        // Sign Up Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "New here? ",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const SignUpScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Create Account',
                                style: TextStyle(
                                  color: settings.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 1.seconds),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
