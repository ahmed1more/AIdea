import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

enum AiModel { aidea, gemini }

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _aideaUrlKey = 'aidea_url';
  static const String _aiModelKey = 'ai_model';
  static const String _apiKeyKey = 'api_key';
  static const String _smartContextKey = 'smart_context';
  static const String _autoSaveKey = 'auto_save';

  ThemeMode _themeMode = ThemeMode.system;
  String _aideaUrl = 'https://atinc1-aidea-server.hf.space';
  AiModel _aiModel = AiModel.aidea;
  String _apiKey = '';
  bool _smartContext = true;
  bool _autoSave = true;

  // Default accent color
  static const Color defaultAccentColor = Color(0xFF6366F1);

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => defaultAccentColor;
  AiModel get aiModel => _aiModel;
  String get apiKey => _apiKey;
  String get aideaUrl => _aideaUrl;
  bool get smartContext => _smartContext;
  bool get autoSave => _autoSave;
  bool get isAiConfigured => _aiModel == AiModel.aidea ? _aideaUrl.isNotEmpty : _apiKey.isNotEmpty;

  String get aiModelLabel => _aiModel == AiModel.aidea ? 'AIdea Engine' : 'Google Gemini';

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[modeIndex];
    _aideaUrl = prefs.getString(_aideaUrlKey) ?? 'https://atinc1-aidea-server.hf.space';
    // Migration: If user has old local URL, migrate it to the new Hugging Face Space URL.
    if (_aideaUrl == 'http://127.0.0.1:7860') {
      _aideaUrl = 'https://atinc1-aidea-server.hf.space';
      await prefs.setString(_aideaUrlKey, _aideaUrl);
    }
    _aiModel = AiModel.values[prefs.getInt(_aiModelKey) ?? 0];
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _smartContext = prefs.getBool(_smartContextKey) ?? true;
    _autoSave = prefs.getBool(_autoSaveKey) ?? true;
    notifyListeners();
  }

  Future<void> setSmartContext(bool value) async {
    _smartContext = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smartContextKey, value);
  }

  Future<void> setAutoSave(bool value) async {
    _autoSave = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSaveKey, value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setAideaUrl(String url) async {
    _aideaUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aideaUrlKey, url);
  }

  Future<void> setAiModel(AiModel model) async {
    _aiModel = model;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_aiModelKey, model.index);
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, key);
  }

  ThemeData getLightTheme() => AppTheme.buildLightTheme(accentColor);
  ThemeData getDarkTheme() => AppTheme.buildDarkTheme(accentColor);

  // Glassmorphism helper
  BoxDecoration glassDecoration({
    required BuildContext context,
    double opacity = 0.1,
    double blur = 10,
    BorderRadius? borderRadius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
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
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(
              alpha: opacity,
            ),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border:
                border ??
                Border.all(
                  color: (isDark ? Colors.white : Colors.black).withValues(
                    alpha: 0.1,
                  ),
                  width: 1.5,
                ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget logo({double size = 80, bool applyTheme = true}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Image.asset(
          'assets/icon/aidea-logo.png',
          width: size,
          height: size,
          color: applyTheme
              ? (isDark ? Colors.white.withValues(alpha: 0.9) : null)
              : null,
          colorBlendMode: applyTheme
              ? (isDark ? BlendMode.modulate : null)
              : null,
        );
      },
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

