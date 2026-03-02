import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
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
          // Background Image
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
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: FaIcon(
                                FontAwesomeIcons.arrowLeft,
                                size: 20,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        // App Logo Animated
                        Center(
                          child: settings
                              .logo(size: 100)
                              .animate()
                              .scale(
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              )
                              .shimmer(delay: 1.seconds, duration: 2.seconds),
                        ),
                        const SizedBox(height: 24),

                        // Header Text
                        Text(
                          'Join AIdea',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            letterSpacing: 1,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().slideY(begin: 0.2),
                        const SizedBox(height: 8),
                        Text(
                          'Start your journey with AI-powered notes.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 40),

                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          icon: FontAwesomeIcons.user,
                          settings: settings,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter your name';
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),

                        // Email Field
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          icon: FontAwesomeIcons.envelope,
                          settings: settings,
                          isDark: isDark,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter your email';
                            if (!value.contains('@'))
                              return 'Enter a valid email';
                            return null;
                          },
                        ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),

                        // Password Field
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: FontAwesomeIcons.lock,
                          settings: settings,
                          isDark: isDark,
                          obscureText: _obscurePassword,
                          toggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Enter a password';
                            if (value.length < 6)
                              return 'At least 6 characters';
                            return null;
                          },
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.1),
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          icon: FontAwesomeIcons.lock,
                          settings: settings,
                          isDark: isDark,
                          obscureText: _obscureConfirmPassword,
                          toggleObscure: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Confirm your password';
                            if (value != _passwordController.text)
                              return 'Passwords do not match';
                            return null;
                          },
                        ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
                        const SizedBox(height: 32),

                        // Sign Up Button
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
                                onPressed: auth.isLoading
                                    ? null
                                    : _handleSignUp,
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
                                        'CREATE ACCOUNT',
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
                        ).animate().fadeIn(delay: 700.ms).scale(),

                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Login',
                                style: TextStyle(
                                  color: settings.accentColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 800.ms),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required SettingsProvider settings,
    required bool isDark,
    bool obscureText = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
        prefixIcon: Icon(icon, size: 18, color: settings.accentColor),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: FaIcon(
                  obscureText
                      ? FontAwesomeIcons.eyeSlash
                      : FontAwesomeIcons.eye,
                  size: 16,
                  color: isDark ? Colors.white60 : Colors.black45,
                ),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: (isDark ? Colors.black : Colors.white).withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
