import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AiModel { aidea, gemini }

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';
  static const String _aiModelKey = 'ai_model';
  static const String _apiKeyKey = 'api_key';
  static const String _aideaUrlKey = 'aidea_url';

  ThemeMode _themeMode = ThemeMode.system;
  int _accentColorIndex = 0;
  AiModel _aiModel = AiModel.gemini;
  String _apiKey = '';
  String _aideaUrl = 'https://atinc1-aidea-server.hf.space';

  // Available accent colors
  static const List<({String name, Color color})> accentColors = [
    (name: 'Indigo', color: Color(0xFF6366F1)),
    (name: 'Teal', color: Color(0xFF14B8A6)),
    (name: 'Rose', color: Color(0xFFF43F5E)),
    (name: 'Orange', color: Color(0xFFF97316)),
    (name: 'Emerald', color: Color(0xFF10B981)),
    (name: 'Sky', color: Color(0xFF0EA5E9)),
    (name: 'Violet', color: Color(0xFF8B5CF6)),
    (name: 'Amber', color: Color(0xFFF59E0B)),
  ];

  ThemeMode get themeMode => _themeMode;
  int get accentColorIndex => _accentColorIndex;
  Color get accentColor => accentColors[_accentColorIndex].color;
  AiModel get aiModel => _aiModel;
  String get apiKey => _apiKey;
  String get aideaUrl => _aideaUrl;
  bool get isAiConfigured {
    if (_aiModel == AiModel.aidea) {
      return true; // Now auto-configured
    }
    return _apiKey.isNotEmpty;
  }

  SettingsProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    _themeMode = ThemeMode.values[modeIndex];
    _accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
    if (_accentColorIndex >= accentColors.length) _accentColorIndex = 0;
    final aiModelIndex = prefs.getInt(_aiModelKey) ?? 0;
    _aiModel = AiModel.values[aiModelIndex];
    _apiKey = prefs.getString(_apiKeyKey) ?? '';
    _aideaUrl =
        prefs.getString(_aideaUrlKey) ?? 'https://atinc1-aidea-server.hf.space';
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setAccentColor(int index) async {
    if (index < 0 || index >= accentColors.length) return;
    _accentColorIndex = index;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, index);
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

  Future<void> setAideaUrl(String url) async {
    _aideaUrl = url;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_aideaUrlKey, url);
  }

  ThemeData getLightTheme() => _buildTheme(Brightness.light);
  ThemeData getDarkTheme() => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final seedColor = accentColor;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.grey.shade50
            : Colors.grey.shade900,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
