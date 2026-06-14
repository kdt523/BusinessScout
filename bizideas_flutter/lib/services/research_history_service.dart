import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/research_history_item.dart';

class ResearchHistoryService {
  static const String _historyKey = 'research_history';

  /// Retrieves the list of research history items from SharedPreferences.
  /// Returns an empty list if no history exists.
  /// Items are sorted by timestamp in descending order (newest first).
  Future<List<ResearchHistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_historyKey);

      if (historyJson == null || historyJson.isEmpty) {
        return [];
      }

      final List<dynamic> historyList = json.decode(historyJson);
      final items = historyList
          .map((item) => ResearchHistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by timestamp, newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return items;
    } catch (e) {
      print('Error loading research history: $e');
      return [];
    }
  }

  /// Adds a new research report to the history.
  /// If a report with the same roomId already exists, it will be updated.
  Future<void> addReport(ResearchHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Remove existing item with same roomId if present
      history.removeWhere((existingItem) => existingItem.roomId == item.roomId);

      // Add new item at the beginning
      history.insert(0, item);

      // Limit history to 100 items (as per design document)
      if (history.length > 100) {
        history.removeRange(100, history.length);
      }

      // Save to SharedPreferences
      final historyJson = json.encode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error adding report to history: $e');
      throw Exception('Unable to save history');
    }
  }

  /// Removes a specific report from the history by roomId.
  Future<void> removeReport(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getHistory();

      // Remove item with matching roomId
      history.removeWhere((item) => item.roomId == roomId);

      // Save updated history
      final historyJson = json.encode(history.map((e) => e.toJson()).toList());
      await prefs.setString(_historyKey, historyJson);
    } catch (e) {
      print('Error removing report from history: $e');
      throw Exception('Unable to remove report');
    }
  }

  /// Clears all research history from storage.
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      print('Error clearing history: $e');
      throw Exception('Unable to clear history');
    }
  }
}
