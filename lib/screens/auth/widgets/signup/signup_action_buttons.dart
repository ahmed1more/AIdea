import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../theme/app_theme.dart';
import '../../../../providers/auth_provider.dart';
import '../../signup_controller.dart';
import '../../../main_shell.dart';

class SignUpActionButtons extends StatelessWidget {
  final VoidCallback onBackToLogin;

  const SignUpActionButtons({super.key, required this.onBackToLogin});

  Future<void> _handleSignUp(BuildContext context) async {
    final controller = context.read<SignUpController>();

    if (controller.formKey.currentState!.validate()) {
      if (!controller.areSelectionsComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please fill in all fields'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      bool success = await authProvider.signUp(
        email: controller.email,
        password: controller.password,
        displayName: controller.fullName,
        gender: controller.selectedGender,
        birthDate: controller.formattedBirthDate,
      );

      if (success && context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainShell()),
          (route) => false,
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage ?? 'Sign up failed'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed:
                    auth.isLoading ? null : () => _handleSignUp(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXl)),
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
                    : Text('Submit',
                        style: AppTheme.button().copyWith(fontSize: 16)),
              ),
            );
          },
        ).animate().fadeIn(delay: 750.ms),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onBackToLogin,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusXl)),
              side: BorderSide(
                  color:
                      isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
            ),
            child: Text('I already have an account',
                style: AppTheme.button().copyWith(fontSize: 16)),
          ),
        ).animate().fadeIn(delay: 800.ms),
      ],
    );
  }
}
