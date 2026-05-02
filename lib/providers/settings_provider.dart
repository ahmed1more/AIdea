import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../theme/app_theme.dart';

class SettingsProvider with ChangeNotifier {
  static const String _accentColorKey = 'accent_color';
  static const String _themeModeKey = 'theme_mode';
  static const String _aideaUrlKey = 'aidea_url';
  static const String _apiKeyKey = 'api_key';

  Color _accentColor = AppTheme.teal;
  ThemeMode _themeMode = ThemeMode.system;
  String _aideaUrl = '';
  String _apiKey = '';

  SettingsProvider() {
    _loadSettings();
  }

  Color get accentColor => _accentColor;
  ThemeMode get themeMode => _themeMode;
  String get aideaUrl => _aideaUrl;
  String get apiKey => _apiKey;

  bool get isAiConfigured => _aideaUrl.isNotEmpty;

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt(_accentColorKey);
    if (colorValue != null) {
      _accentColor = Color(colorValue);
    }

    final modeIndex = prefs.getInt(_themeModeKey);
    if (modeIndex != null) {
      _themeMode = ThemeMode.values[modeIndex];
    }

    _aideaUrl = prefs.getString(_aideaUrlKey) ?? dotenv.maybeGet('AIDEA_BASE_URL') ?? '';
    _apiKey = prefs.getString(_apiKeyKey) ?? '';

    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, color.toARGB32());
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> updateAiSettings({
    required String url,
    required String key,
  }) async {
    _aideaUrl = url;
    _apiKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aideaUrlKey, url);
    await prefs.setString(_apiKeyKey, key);
  }

  String backgroundAssetPath(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? 'assets/images/signup_bg.png'
        : 'assets/images/signup_bg_light.png';
  }

  Widget buildBackground({
    required BuildContext context,
    required Widget child,
    double darkOpacity = 0.6,
    double lightOpacity = 0.7,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            backgroundAssetPath(context),
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: (isDark ? AppTheme.darkBg : AppTheme.lightBg).withValues(
              alpha: isDark ? darkOpacity : lightOpacity,
            ),
          ),
        ),
        child,
      ],
    );
  }

  ThemeData getLightTheme() => AppTheme.buildLightTheme(accentColor);
  ThemeData getDarkTheme() => AppTheme.buildDarkTheme(accentColor);

  String logoAssetPath(BuildContext context) {
    return 'assets/icon/aidea-logo-transparent.png';
  }

  // Glassmorphism helper
  BoxDecoration glassDecoration({
    required BuildContext context,
    double opacity = 0.1,
    double blur = 10,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : AppTheme.lightSurface;
    final borderColor = isDark ? Colors.white : AppTheme.lightDivider;
    return BoxDecoration(
      color: baseColor.withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: borderColor.withValues(alpha: isDark ? 0.1 : 0.7),
        width: 1.5,
      ),
    );
  }

  Widget glassMorphicContainer({
    required BuildContext context,
    required Widget child,
    double opacity = 0.1,
    double blur = 20, // Increased default blur for a more premium look
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Border? border,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.white;
    final borderColor = isDark ? Colors.white : AppTheme.lightDivider;
    final useBackdropBlur =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.android;
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor.withValues(
          alpha: opacity,
        ),
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border:
            border ??
            Border.all(
              color: borderColor.withValues(
                alpha: isDark ? 0.1 : 0.9,
              ),
              width: 1.5,
            ),
      ),
      child: child,
    );
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: useBackdropBlur
          ? BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: content,
            )
          : content,
    );
  }

  Widget logo({double size = 120, bool applyTheme = true}) {
    return Image.asset(
      'assets/icon/aidea-logo-transparent.png',
      width: size,
      height: size,
    );
  }

  Future<T?> showGlassDialog<T>({
    required BuildContext context,
    required Widget content,
    String? title,
    List<Widget>? actions,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: glassMorphicContainer(
                  context: context,
                  opacity: 0.1,
                  blur: 25,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null) ...[
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      content,
                      if (actions != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
