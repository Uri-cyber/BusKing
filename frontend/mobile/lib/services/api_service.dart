import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../models/route.dart';
import '../models/checklist_item.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConfig.tokenKey);
  }

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConfig.tokenKey, token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConfig.tokenKey);
  }

  Map<String, String> get headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Auth APIs
  Future<Map<String, dynamic>> register(String phoneNumber, String? name) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        if (name != null) 'name': name,
      }),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verify(String phoneNumber, String code) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone_number': phoneNumber,
        'code': code,
      }),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['data']?['token'] != null) {
        await saveToken(data['data']['token']);
      }
      return data;
    } else {
      throw Exception('Verification failed: ${response.body}');
    }
  }

  Future<User> getProfile() async {
    await loadToken();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/me'),
      headers: headers,
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromJson(data['data']);
    } else {
      throw Exception('Get profile failed: ${response.body}');
    }
  }

  Future<void> updateSettings(UserSettings settings) async {
    await loadToken();
    final response = await http.put(
      Uri.parse('${AppConfig.apiBaseUrl}/auth/settings'),
      headers: headers,
      body: jsonEncode(settings.toJson()),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Update settings failed: ${response.body}');
    }
  }

  // Routes APIs
  Future<UserRoute> createRoute(Map<String, dynamic> routeData) async {
    await loadToken();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/routes'),
      headers: headers,
      body: jsonEncode(routeData),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return UserRoute.fromJson(data['data']['route']);
    } else {
      throw Exception('Create route failed: ${response.body}');
    }
  }

  Future<List<UserRoute>> getRoutes() async {
    await loadToken();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/routes'),
      headers: headers,
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((route) => UserRoute.fromJson(route))
          .toList();
    } else {
      throw Exception('Get routes failed: ${response.body}');
    }
  }

  Future<void> deleteRoute(String routeId) async {
    await loadToken();
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/routes/$routeId'),
      headers: headers,
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Delete route failed: ${response.body}');
    }
  }

  Future<void> toggleRoute(String routeId, bool isActive) async {
    await loadToken();
    final response = await http.patch(
      Uri.parse('${AppConfig.apiBaseUrl}/routes/$routeId/toggle'),
      headers: headers,
      body: jsonEncode({'is_active': isActive}),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Toggle route failed: ${response.body}');
    }
  }

  // Checklist APIs
  Future<List<ChecklistItem>> getChecklist() async {
    await loadToken();
    final response = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}/checklist'),
      headers: headers,
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data'] as List)
          .map((item) => ChecklistItem.fromJson(item))
          .toList();
    } else {
      throw Exception('Get checklist failed: ${response.body}');
    }
  }

  Future<ChecklistItem> createChecklistItem(String itemName, String? emoji, String? context) async {
    await loadToken();
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/checklist'),
      headers: headers,
      body: jsonEncode({
        'item_name': itemName,
        if (emoji != null) 'emoji': emoji,
        if (context != null) 'context': context,
      }),
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return ChecklistItem.fromJson(data['data']);
    } else {
      throw Exception('Create checklist item failed: ${response.body}');
    }
  }

  Future<void> deleteChecklistItem(String itemId) async {
    await loadToken();
    final response = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}/checklist/$itemId'),
      headers: headers,
    ).timeout(AppConfig.apiTimeout);

    if (response.statusCode != 200) {
      throw Exception('Delete checklist item failed: ${response.body}');
    }
  }
}
