import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class NutritionDatabase {
  static const String remoteUrl = "https://firebasestorage.googleapis.com/v0/b/fytlyf-production-realtime.firebasestorage.app/o/nutrition%2Fnutrition_10000.json?alt=media&token=a84e1d82-f44d-47ee-a0e0-aedcb71a7a32";

  static List<dynamic> _foods = [];

  static bool initialized = false;

  static Future<void> init() async {
    if (initialized) return;
    initialized = true;

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/nutrition.json");

    // Load local cache first (fast)
    if (await file.exists()) {
      try {
        final text = await file.readAsString();
        _foods = json.decode(text);
        debugPrint("Nutrition DB loaded locally (${_foods.length} items)");
      } catch (_) {}
    }

    // Download latest version (async update)
    try {
      final response = await http.get(Uri.parse(remoteUrl));
      if (response.statusCode == 200) {
        await file.writeAsString(response.body);
        _foods = json.decode(response.body);
        debugPrint("Nutrition DB updated from cloud (${_foods.length} items)");
      }
    } catch (e) {
      debugPrint("Nutrition DB fetch error: $e");
    }
  }

  /// Fuzzy search (D2): startsWith priority + substring
  static List<Map<String, dynamic>> search(String query, {int limit = 50}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final List<Map<String, dynamic>> results = [];

    for (var item in _foods) {
      final name = (item["name"] ?? "").toString().toLowerCase();

      if (name.startsWith(q)) {
        results.insert(0, Map<String, dynamic>.from(item));
      } else if (name.contains(q)) {
        results.add(Map<String, dynamic>.from(item));
      }

      if (results.length >= limit) break;
    }

    return results;
  }

  static List<dynamic> get all => _foods;
}
