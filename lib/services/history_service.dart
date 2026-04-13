import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class HistoryService {
  static const _historyKey = 'color_history';

  Future<void> addColorToHistory(ColorData color) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Avoid duplicates by hex
    history.removeWhere((c) => c.hex.toUpperCase() == color.hex.toUpperCase());
    
    // Add to the beginning (most recent first)
    history.insert(0, color);
    
    final String encodedData = jsonEncode(history.map((c) => c.toJson()).toList());
    await prefs.setString(_historyKey, encodedData);
  }

  Future<void> removeColorFromHistory(String hex) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    history.removeWhere((c) => c.hex.toUpperCase() == hex.toUpperCase());
    
    final String encodedData = jsonEncode(history.map((c) => c.toJson()).toList());
    await prefs.setString(_historyKey, encodedData);
  }

  Future<List<ColorData>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_historyKey);
    
    if (encodedData != null) {
      try {
        final List<dynamic> decodedData = jsonDecode(encodedData);
        return decodedData.map((item) => ColorData.fromJson(item)).toList();
      } catch (e) {
        print('Error decoding history: $e');
        return [];
      }
    }
    
    return [];
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
