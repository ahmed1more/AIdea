import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/settings_provider.dart';
import '../main_shell.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;

    String label;
    if (strength <= 0.25) {
      label = 'Weak';
    } else if (strength <= 0.5) {
      label = 'Fair';
    } else if (strength <= 0.75) {
      label = 'Good';
    } else {
      label = 'Strong';
    }

    setState(() {
      _passwordStrength = password.isEmpty ? 0 : strength;
      _passwordStrengthLabel = password.isEmpty ? '' : label;
    });
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updatePasswordStrength);
    _firstNameController.dispose();
    _surnameController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDay == null || _selectedMonth == null || _selectedYear == null || _selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in all fields'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signUp(
        email: _contactController.text.trim(),
        password: _passwordController.text,
        displayName: '${_firstNameController.text.trim()} ${_surnameController.text.trim()}',
      );

      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(bool isDark, String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: isDark ? AppTheme.darkSurface.withValues(alpha: 0.5) : AppTheme.lightSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
    );
  }

  Widget _buildDropdown(bool isDark, String hint, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      hint: Text(hint, style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary), overflow: TextOverflow.ellipsis),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),)).toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      icon: Icon(Icons.keyboard_arrow_down, color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
      decoration: _inputDecoration(isDark, hint),
      isExpanded: true,
    );
  }

  Widget _buildLegalText(bool isDark) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
    final style = AppTheme.bodySmall(color: mutedColor).copyWith(height: 1.4, fontSize: 11);
    final linkStyle = style.copyWith(color: primaryColor, fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People who use our service may have uploaded your contact information to AIdea.',
          style: style,
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'By tapping Submit, you agree to create an account and to AIdea\'s '),
              TextSpan(text: 'Terms', style: linkStyle),
              const TextSpan(text: ', '),
              TextSpan(text: 'Privacy Policy', style: linkStyle),
              const TextSpan(text: ' and '),
              TextSpan(text: 'Cookies Policy', style: linkStyle),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The Privacy Policy describes the ways we can use the information we collect when you create an account. For example, we use this information to provide, personalise and improve our products.',
          style: style,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);

    Widget formContent = CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ─── Top Bar ────────────────────────────────
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.darkSurface : AppTheme.lightTextPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: settings.logo(size: 18, applyTheme: false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'AIdea',
                            style: AppTheme.headline3(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 24),

                      // ─── Headline ────────────────────────────
                      Text(
                        'Get started on AIdea',
                        style: AppTheme.headline2(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to access your editorial intelligence and connect with your team.',
                        style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ).animate().fadeIn(delay: 150.ms),
                      const SizedBox(height: 24),

                      // ─── Name ────────────────────────────────
                      Text(
                        'Name',
                        style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                              decoration: _inputDecoration(isDark, 'First name'),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ).animate().fadeIn(delay: 250.ms),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _surnameController,
                              style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                              decoration: _inputDecoration(isDark, 'Surname'),
                              validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                            ).animate().fadeIn(delay: 250.ms),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Date of birth ────────────────────────
                      Text(
                        'Date of birth',
                        style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 300.ms),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              isDark, 'Day',
                              List.generate(31, (i) => (i + 1).toString()),
                              _selectedDay,
                              (v) => setState(() => _selectedDay = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              isDark, 'Month',
                              ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
                              _selectedMonth,
                              (v) => setState(() => _selectedMonth = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              isDark, 'Year',
                              List.generate(100, (i) => (DateTime.now().year - i).toString()),
                              _selectedYear,
                              (v) => setState(() => _selectedYear = v),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 350.ms),
                      const SizedBox(height: 20),

                      // ─── Gender ──────────────────────────────
                      Text(
                        'Gender',
                        style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 6),
                      _buildDropdown(
                        isDark,
                        'Select your gender',
                        ['Female', 'Male', 'Custom', 'Prefer not to say'],
                        _selectedGender,
                        (v) => setState(() => _selectedGender = v),
                      ).animate().fadeIn(delay: 450.ms),
                      const SizedBox(height: 20),

                      // ─── Mobile or Email ─────────────────────
                      Text(
                        'Mobile number or email address',
                        style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 500.ms),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _contactController,
                        style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                        decoration: _inputDecoration(isDark, 'Mobile number or email address'),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ).animate().fadeIn(delay: 550.ms),
                      const SizedBox(height: 4),
                      Text(
                        'You may receive notifications from us.',
                        style: AppTheme.bodySmall(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
                      ).animate().fadeIn(delay: 600.ms),
                      const SizedBox(height: 20),

                      // ─── Password ────────────────────────────
                      Text(
                        'Password',
                        style: AppTheme.labelLarge(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                      ).animate().fadeIn(delay: 650.ms),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTheme.bodyMedium(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
                        decoration: _inputDecoration(isDark, 'Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 8) return 'At least 8 characters';
                          if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include at least one uppercase letter';
                          if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include at least one lowercase letter';
                          if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include at least one number';
                          if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(value)) return 'Include at least one special character';
                          return null;
                        },
                      ).animate().fadeIn(delay: 700.ms),

                      // ─── Password Strength Indicator ──────────
                      if (_passwordController.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 4,
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength,
                                    backgroundColor: (isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _passwordStrength <= 0.25
                                          ? Colors.red
                                          : _passwordStrength <= 0.5
                                              ? Colors.orange
                                              : _passwordStrength <= 0.75
                                                  ? Colors.amber
                                                  : Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _passwordStrengthLabel,
                              style: AppTheme.labelSmall(
                                color: _passwordStrength <= 0.25
                                    ? Colors.red
                                    : _passwordStrength <= 0.5
                                        ? Colors.orange
                                        : _passwordStrength <= 0.75
                                            ? Colors.amber
                                            : Colors.green,
                              ).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use 8+ characters with uppercase, lowercase, numbers & symbols',
                          style: AppTheme.bodySmall(
                            color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                          ).copyWith(fontSize: 11),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // ─── Legal Text ──────────────────────────
                      _buildLegalText(isDark).animate().fadeIn(delay: 750.ms),
                      const SizedBox(height: 32),

                      // ─── Buttons ─────────────────────────────
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          return SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                                elevation: 0,
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text('Submit', style: AppTheme.button().copyWith(fontSize: 16)),
                            ),
                          );
                        },
                      ).animate().fadeIn(delay: 800.ms),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
                            side: BorderSide(color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
                          ),
                          child: Text('I already have an account', style: AppTheme.button().copyWith(fontSize: 16)),
                        ),
                      ).animate().fadeIn(delay: 850.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: Stack(
        children: [
          // ─── Background ───────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/signup_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: (isDark ? AppTheme.darkBg : AppTheme.lightBg).withValues(alpha: isDark ? 0.6 : 0.7),
            ),
          ),

          // ─── Main Content ────────────────────────────
          SafeArea(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: formContent,
            ),
          ),
        ],
      ),
    );
  }
}


