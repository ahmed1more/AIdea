import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/analytics_model.dart';
import '../services/database_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();

  AnalyticsModel? _analytics;
  StreamSubscription? _analyticsSubscription;
  bool _isLoading = false;

  AnalyticsModel? get analytics => _analytics;
  bool get isLoading => _isLoading;

  // Load user analytics
  void loadUserAnalytics(String userId) {
    _analyticsSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _analyticsSubscription = _databaseService
        .getUserAnalytics(userId)
        .listen(
          (analyticsData) {
            debugPrint(
              'Analytics received: ${analyticsData?.notesCount}',
            ); // ADD THIS
            _analytics = analyticsData;
            _isLoading = false;
            notifyListeners();
          },
          onError: (error) {
            debugPrint('Analytics stream error: $error');
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  // Clear data (on logout)
  void clear() {
    _analyticsSubscription?.cancel();
    _analytics = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _analyticsSubscription?.cancel();
    super.dispose();
  }
}
