import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  /// Save the task history to local storage
  Future<void> saveTaskHistory(List<Map<String, dynamic>> taskHistory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('taskHistory', jsonEncode(taskHistory));
    } catch (e) {
      print('Error saving task history: $e');
    }
  }


}
