import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class NutritionDatabase {
  /// -----------------------------------------------------------
  /// ✅ Correct Firebase Storage URL  (PUBLIC DOWNLOAD LINK)
  /// Make sure this exists:
  /// storage > nutrition > nutrition_10000.json
  /// -----------------------------------------------------------
  static const String remoteUrl =
      "https://firebasestorage.googleapis.com/v0/b/fytlyf-production-realtime.appspot.com/o/nutrition%2Fnutrition_10000.json?alt=media";

  /// internal list
  static List<dynamic> _foods = [];

  static bool initialized = false;

  /// -----------------------------------------------------------
  /// INIT — Load Local → then Refresh from Cloud
  /// -----------------------------------------------------------
  static Future<void> init() async {
    if (initialized) return;
    initialized = true;

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/nutrition.json");

    // Load local copy (FAST)
    if (await file.exists()) {
      try {
        final text = await file.readAsString();
        _foods = json.decode(text);
        debugPrint("⭐ Loaded local nutrition DB (${_foods.length})");
      } catch (_) {}
    }

    // Download fresh copy
    try {
      final resp = await http.get(Uri.parse(remoteUrl));
      if (resp.statusCode == 200) {
        await file.writeAsString(resp.body);
        _foods = json.decode(resp.body);
        debugPrint("🔥 Updated nutrition DB from Cloud (${_foods.length})");
      }
    } catch (e) {
      debugPrint("❌ Nutrition DB fetch error: $e");
    }
  }

  /// -----------------------------------------------------------
  /// SEARCH — Optimized for large dataset (10k–100k)
  /// -----------------------------------------------------------
  static List<Map<String, dynamic>> search(String query, {int limit = 50}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final List<Map<String, dynamic>> results = [];

    for (var item in _foods) {
      final name = (item["name"] ?? "").toString().toLowerCase();

      // Starts-with = highest priority
      if (name.startsWith(q)) {
        results.insert(0, Map<String, dynamic>.from(item));
      }
      // contains = lower priority
      else if (name.contains(q)) {
        results.add(Map<String, dynamic>.from(item));
      }

      if (results.length >= limit) break;
    }
    return results;
  }

  /// -----------------------------------------------------------
  /// FIND FOOD BY ID (for Firestore retrieval)
  /// -----------------------------------------------------------
  static Map<String, dynamic>? findById(dynamic id) {
    try {
      return _foods.firstWhere(
            (f) => f["id"].toString() == id.toString(),
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// -----------------------------------------------------------
  /// CALCULATE NUTRITION VIA JSON SYSTEM
  ///
  /// Example:
  ///  id: 501 (milk)
  ///  unit: "cup"
  ///  amount: 1
  ///
  /// Uses:
  ///   measures → convert cup → gram
  ///   nutrition_per_100g → scale macros
  /// -----------------------------------------------------------
  static Map<String, dynamic> calculateNutrition({
    required Map<String, dynamic> food,
    required String unit,
    required double amount,
  }) {
    try {
      final base100 = food["nutrition_per_100g"];
      final measures = food["measures"];

      if (measures == null || !measures.containsKey(unit)) {
        return {
          "calories": 0.0,
          "protein": 0.0,
          "carbs": 0.0,
          "fat": 0.0,
          "weight_gram": 0.0,
        };
      }

      // Amount to grams
      final double gramValueOfUnit = measures[unit].toDouble();
      final double totalGram = gramValueOfUnit * amount;

      // Multiply values relative to 100g
      final ratio = totalGram / 100.0;

      return {
        "calories": (base100["calories"] * ratio),
        "protein": (base100["protein"] * ratio),
        "carbs": (base100["carbs"] * ratio),
        "fat": (base100["fat"] * ratio),
        "weight_gram": totalGram,
      };
    } catch (e) {
      debugPrint("❌ Nutrition calculation error: $e");
      return {
        "calories": 0.0,
        "protein": 0.0,
        "carbs": 0.0,
        "fat": 0.0,
        "weight_gram": 0.0,
      };
    }
  }

  /// Get all food items
  static List<dynamic> get all => _foods;
}
