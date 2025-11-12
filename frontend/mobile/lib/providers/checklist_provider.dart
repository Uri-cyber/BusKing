import 'package:flutter/material.dart';
import '../models/checklist_item.dart';
import '../services/api_service.dart';

class ChecklistProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<ChecklistItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<ChecklistItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadChecklist() async {
    _isLoading = true;
    notifyListeners();

    try {
      _items = await _apiService.getChecklist();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createItem(String itemName, String? emoji, String? context) async {
    try {
      final newItem = await _apiService.createChecklistItem(itemName, emoji, context);
      _items.add(newItem);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteChecklistItem(itemId);
      _items.removeWhere((item) => item.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
