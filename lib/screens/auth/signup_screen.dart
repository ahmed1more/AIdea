import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/settings_provider.dart';
import 'login_screen.dart';
import 'signup_controller.dart';
import 'widgets/signup/signup_top_bar.dart';
import 'widgets/signup/signup_headline.dart';
import 'widgets/signup/signup_name_fields.dart';
import 'widgets/signup/signup_date_of_birth.dart';
import 'widgets/signup/signup_gender_dropdown.dart';
import 'widgets/signup/signup_contact_field.dart';
import 'widgets/signup/signup_password_field.dart';
import 'widgets/signup/signup_action_buttons.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SignUpController(),
      child: const _SignUpBody(),
    );
  }
}

class _SignUpBody extends StatelessWidget {
  const _SignUpBody();

  void _handleBackNavigation(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = Provider.of<SettingsProvider>(context);
    final controller = context.watch<SignUpController>();

    Widget formContent = LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: controller.formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Top Bar ────────────────────────────────
                    SignUpTopBar(
                        onBack: () => _handleBackNavigation(context)),
                    const SizedBox(height: 24),

                    // ─── Headline ────────────────────────────
                    const SignUpHeadline(),
                    const SizedBox(height: 24),

                    // ─── Name ────────────────────────────────
                    const SignUpNameFields(),
                    const SizedBox(height: 20),

                    // ─── Date of birth ────────────────────────
                    const SignUpDateOfBirth(),
                    const SizedBox(height: 20),

                    // ─── Gender ──────────────────────────────
                    const SignUpGenderDropdown(),
                    const SizedBox(height: 20),

                    // ─── Mobile or Email ─────────────────────
                    const SignUpContactField(),
                    const SizedBox(height: 20),

                    // ─── Password ────────────────────────────
                    const SignUpPasswordField(),
                    const SizedBox(height: 24),

                    // ─── Buttons ─────────────────────────────
                    SignUpActionButtons(
                        onBackToLogin: () =>
                            _handleBackNavigation(context)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      body: settings.buildBackground(
        context: context,
        child: SafeArea(
          child: controller.useBackdropBlur
              ? BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: formContent,
                )
              : formContent,
        ),
      ),
    );
  }
}
