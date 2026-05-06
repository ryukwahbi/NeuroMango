import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'theme.dart';

// ==========================================
// API Helper Functions
// ==========================================
Future<bool> saveAnalysisResult(Map<String, dynamic> result) async {
  try {
    final response = await http
        .post(
          Uri.parse('$apiBaseUrl/save-result'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(result),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('Result saved to backend: ${response.body}');
      return true;
    } else {
      debugPrint('Failed to save result: ${response.statusCode}');
      return false;
    }
  } catch (e) {
    debugPrint('Error saving to backend: $e');
    return false;
  }
}

Future<Map<String, dynamic>?> getAnalysisHistory() async {
  try {
    final response = await http
        .get(
          Uri.parse('$apiBaseUrl/history'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
  } catch (e) {
    debugPrint('Error fetching history: $e');
  }
  return null;
}
