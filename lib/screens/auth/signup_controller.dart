import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SignUpController extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final surnameController = TextEditingController();
  final contactController = TextEditingController();
  final passwordController = TextEditingController();

  bool _obscurePassword = true;
  double _passwordStrength = 0;
  String _passwordStrengthLabel = '';

  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedGender;

  // ── Getters ───────────────────────────────────────────────
  bool get obscurePassword => _obscurePassword;
  double get passwordStrength => _passwordStrength;
  String get passwordStrengthLabel => _passwordStrengthLabel;
  String? get selectedDay => _selectedDay;
  String? get selectedMonth => _selectedMonth;
  String? get selectedYear => _selectedYear;
  String? get selectedGender => _selectedGender;

  bool get useBackdropBlur =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

  bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  bool get areSelectionsComplete =>
      _selectedDay != null &&
      _selectedMonth != null &&
      _selectedYear != null &&
      _selectedGender != null;

  String get fullName =>
      '${firstNameController.text.trim()} ${surnameController.text.trim()}';

  String get email => contactController.text.trim();

  String get password => passwordController.text;

  String get formattedBirthDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthNum =
        (months.indexOf(_selectedMonth!) + 1).toString().padLeft(2, '0');
    final dayNum = _selectedDay!.padLeft(2, '0');
    return '$_selectedYear-$monthNum-$dayNum';
  }

  // ── Constructor ───────────────────────────────────────────
  SignUpController() {
    passwordController.addListener(_updatePasswordStrength);
  }

  // ── Setters ───────────────────────────────────────────────
  void setDay(String? v) {
    _selectedDay = v;
    notifyListeners();
  }

  void setMonth(String? v) {
    _selectedMonth = v;
    notifyListeners();
  }

  void setYear(String? v) {
    _selectedYear = v;
    notifyListeners();
  }

  void setGender(String? v) {
    _selectedGender = v;
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  // ── Password strength logic ───────────────────────────────
  void _updatePasswordStrength() {
    final password = passwordController.text;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>]').hasMatch(password)) {
      strength += 0.25;
    }

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

    _passwordStrength = password.isEmpty ? 0 : strength;
    _passwordStrengthLabel = password.isEmpty ? '' : label;
    notifyListeners();
  }

  // ── Shared input decoration ───────────────────────────────
  InputDecoration inputDecoration(
      BuildContext context, bool isDark, String hint) {
    final fillColor = isDark
        ? (isAndroid
            ? AppTheme.darkSurfaceHigh.withValues(alpha: 0.88)
            : AppTheme.darkSurface.withValues(alpha: 0.5))
        : AppTheme.lightSurface;
    final secondaryTextColor = isDark
        ? (isAndroid
            ? AppTheme.darkTextPrimary.withValues(alpha: 0.82)
            : AppTheme.darkTextSecondary)
        : AppTheme.lightTextSecondary;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(
            color: isDark ? AppTheme.darkDivider : AppTheme.lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppTheme.bodyMedium(color: secondaryTextColor),
    );
  }

  // ── Shared dropdown builder ───────────────────────────────
  Widget buildDropdown(
    BuildContext context,
    bool isDark,
    String hint,
    List<String> items,
    String? selectedValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      hint: Text(
        hint,
        style: AppTheme.bodyMedium(
          color: isDark
              ? AppTheme.darkTextSecondary
              : AppTheme.lightTextSecondary,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      items: items
          .map((i) => DropdownMenuItem(
                value: i,
                child: Text(
                  i,
                  style: AppTheme.bodyMedium(
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.lightTextPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      icon: Icon(
        Icons.keyboard_arrow_down,
        color:
            isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
      ),
      decoration: inputDecoration(context, isDark, hint),
      isExpanded: true,
    );
  }

  // ── Dispose ───────────────────────────────────────────────
  @override
  void dispose() {
    passwordController.removeListener(_updatePasswordStrength);
    firstNameController.dispose();
    surnameController.dispose();
    contactController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
