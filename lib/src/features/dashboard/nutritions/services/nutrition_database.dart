// file: lib/src/features/dashboard/nutritions/services/nutrition_database.dart
// Local JSON nutrition database loader + search engine.
// Exposes init(), loadDatabase(), search(), foodById()

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class NutritionDatabase {
  static List<Map<String, dynamic>> _foods = [];
  static bool _loaded = false;

  /// Backwards-compatible initializer used in main.dart
  /// You can call either NutritionDatabase.init() or NutritionDatabase.loadDatabase()
  static Future<void> init() async => loadDatabase();

  /// Load the JSON file from assets and parse into memory.
  static Future<void> loadDatabase() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/nutrition.json');
      final List parsed = json.decode(jsonStr) as List;
      _foods = parsed.map<Map<String, dynamic>>((e) {
        return Map<String, dynamic>.from(e as Map);
      }).toList();
    } catch (e) {
      // If load fails, keep empty but mark loaded to avoid repeated attempts
      _foods = [];
    } finally {
      _loaded = true;
    }
  }

  /// Fast case-insensitive search by name (partial match)
  static Future<List<Map<String, dynamic>>> search(String query, {int limit = 50}) async {
    if (!_loaded) await loadDatabase();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return [];
    final results = <Map<String, dynamic>>[];
    for (final item in _foods) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      if (name.contains(q)) {
        results.add(item);
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  /// Return all foods (rarely needed)
  static Future<List<Map<String, dynamic>>> allFoods() async {
    if (!_loaded) await loadDatabase();
    return _foods;
  }

  /// Find a food by its numeric id
  static Map<String, dynamic>? foodById(dynamic id) {
    if (!_loaded) {
      // Not awaited here to keep API sync — caller should call init() at app start
      // but also be defensive and do a linear search (may return null)
    }
    if (id == null) return null;
    try {
      // support string or num id
      if (id is String) {
        final intId = int.tryParse(id);
        if (intId != null) {
          return _foods.firstWhere((e) => (e['id'] is num ? (e['id'] as num).toInt() : e['id']) == intId, orElse: () => {});
        }
      } else if (id is num) {
        final intId = id.toInt();
        return _foods.firstWhere((e) => (e['id'] is num ? (e['id'] as num).toInt() : e['id']) == intId, orElse: () => {});
      } else if (id is int) {
        return _foods.firstWhere((e) => (e['id'] is num ? (e['id'] as num).toInt() : e['id']) == id, orElse: () => {});
      }
    } catch (_) {}
    return null;
  }
}
