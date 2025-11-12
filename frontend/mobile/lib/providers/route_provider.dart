import 'package:flutter/material.dart';
import '../models/route.dart';
import '../services/api_service.dart';

class RouteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<UserRoute> _routes = [];
  bool _isLoading = false;
  String? _error;

  List<UserRoute> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRoutes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _routes = await _apiService.getRoutes();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createRoute(Map<String, dynamic> routeData) async {
    try {
      final newRoute = await _apiService.createRoute(routeData);
      _routes.add(newRoute);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRoute(String routeId) async {
    try {
      await _apiService.deleteRoute(routeId);
      _routes.removeWhere((route) => route.id == routeId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleRoute(String routeId, bool isActive) async {
    try {
      await _apiService.toggleRoute(routeId, isActive);
      final index = _routes.indexWhere((route) => route.id == routeId);
      if (index != -1) {
        _routes[index] = _routes[index].copyWith(isActive: isActive);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
