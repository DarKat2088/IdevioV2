import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveIdeaHistory(String userId, List<String> ideas) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'history_$userId';
  await prefs.setString(key, jsonEncode(ideas));
}

Future<List<String>> loadIdeaHistory(String userId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'history_$userId';
  final jsonString = prefs.getString(key);
  if (jsonString != null) {
    return List<String>.from(jsonDecode(jsonString));
  }
  return [];
}