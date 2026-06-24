import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../services/database_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  AnalyticsModel? _analytics;
  StreamSubscription? _analyticsSubscription;

  AnalyticsModel? get analytics => _analytics;

  // Load user analytics
  void loadUserAnalytics(String userId) {
    _analyticsSubscription?.cancel();
    _analyticsSubscription = _databaseService.getUserAnalytics(userId).listen(
      (analyticsData) {
        _analytics = analyticsData;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Analytics stream error: $error');
      },
    );
  }

  // Clear data (on logout)
  void clear() {
    _analyticsSubscription?.cancel();
    _analytics = null;
    notifyListeners();
  }
}
