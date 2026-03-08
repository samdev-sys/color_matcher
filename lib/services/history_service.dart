import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class HistoryService {
  static const _historyKey = 'color_history';

  Future<void> addColorToHistory(ColorData color) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Avoid duplicates
    if (!history.any((c) => c.hex == color.hex)) {
      history.add(color);
      final String encodedData = jsonEncode(history.map((c) => c.toJson()).toList());
      await prefs.setString(_historyKey, encodedData);
    }
  }

  Future<List<ColorData>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_historyKey);
    
    if (encodedData != null) {
      final List<dynamic> decodedData = jsonDecode(encodedData);
      return decodedData.map((item) => ColorData.fromJson(item)).toList();
    }
    
    return [];
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
