import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/route.dart';

class TrackingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _error;
  String? _currentSessionId;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentSessionId => _currentSessionId;

  /// Start tracking a route
  Future<String?> startTracking(UserRoute route) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.startTracking(
        routeId: route.id,
        stopId: route.stopId,
        routeNumber: route.routeNumber,
      );

      if (response['success'] == true) {
        _currentSessionId = response['session_id'];
        _isLoading = false;
        notifyListeners();
        return _currentSessionId;
      } else {
        throw Exception(response['message'] ?? 'Failed to start tracking');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Stop tracking
  Future<bool> stopTracking(String sessionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.stopTracking(sessionId);

      if (response['success'] == true) {
        _currentSessionId = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception(response['message'] ?? 'Failed to stop tracking');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get tracking status
  Future<Map<String, dynamic>?> getTrackingStatus(String sessionId) async {
    try {
      final response = await _apiService.getTrackingStatus(sessionId);
      return response;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _isLoading = false;
    _error = null;
    _currentSessionId = null;
    notifyListeners();
  }
}
