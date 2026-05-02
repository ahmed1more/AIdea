import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// One-time profile completion screen shown after Google sign-in when
/// the user doesn't have gender or birthDate filled in.
class ProfileCompletionScreen extends StatefulWidget {
  /// Called when the user saves or skips — pass true to pop, etc.
  final VoidCallback onComplete;

  const ProfileCompletionScreen({super.key, required this.onComplete});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _isSaving = false;

  static const _genders = ['Male', 'Female'];

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 20),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 5),
      helpText: 'SELECT BIRTH DATE',
    );
    if (picked != null) setState(() => _selectedBirthDate = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final auth = context.read<AuthProvider>();
    await auth.updateProfileCompletion(
      gender: _selectedGender,
      birthDate: _selectedBirthDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
          : null,
    );

    if (mounted) setState(() => _isSaving = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final auth = context.watch<AuthProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 48,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, primary.withValues(alpha: 0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 20),
                    Text(
                      'Complete Your Profile',
                      style: AppTheme.headline3(
                        color: isDark
                            ? AppTheme.darkTextPrimary
                            : AppTheme.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 8),
                    Text(
                      'Help us personalise your experience.\nYou can update this anytime in Settings.',
                      style: AppTheme.bodySmall(
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 250.ms),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Gender ──────────────────────────────────────────
              Text(
                'GENDER',
                style: AppTheme.labelSmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(letterSpacing: 2),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _genders.map((g) {
                  final selected = _selectedGender == g;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedGender = g),
                    child: AnimatedContainer(
                      duration: 200.ms,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? primary
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04)),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: selected
                              ? primary
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.1)),
                        ),
                      ),
                      child: Text(
                        g,
                        style: AppTheme.bodySmall(
                          color: selected
                              ? Colors.white
                              : (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary),
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 28),

              // ── Birth Date ──────────────────────────────────────
              Text(
                'DATE OF BIRTH',
                style: AppTheme.labelSmall(
                  color: isDark
                      ? AppTheme.darkTextSecondary
                      : AppTheme.lightTextSecondary,
                ).copyWith(letterSpacing: 2),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _pickDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedBirthDate != null
                          ? primary.withValues(alpha: 0.5)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.12)
                                : Colors.black.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cake_outlined,
                        size: 18,
                        color: _selectedBirthDate != null
                            ? primary
                            : (isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.lightTextSecondary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _selectedBirthDate != null
                            ? DateFormat('MMMM d, yyyy')
                                .format(_selectedBirthDate!)
                            : 'Select your birth date',
                        style: AppTheme.bodyMedium(
                          color: _selectedBirthDate != null
                              ? (isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary)
                              : (isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 36),

              // ── Actions ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSaving ? null : widget.onComplete,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Skip for now'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_isSaving ||
                                  (_selectedGender == null &&
                                      _selectedBirthDate == null))
                              ? null
                              : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            primary.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                        shadowColor: primary.withValues(alpha: 0.3),
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            )
                          : const Text(
                              'Save Profile',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

              const SizedBox(height: 8),

              // ── Signed in as ─────────────────────────────────────
              Center(
                child: Text(
                  'Signed in as ${auth.user?.email ?? ''}',
                  style: AppTheme.bodySmall(
                    color: isDark
                        ? AppTheme.darkTextSecondary.withValues(alpha: 0.5)
                        : AppTheme.lightTextSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
