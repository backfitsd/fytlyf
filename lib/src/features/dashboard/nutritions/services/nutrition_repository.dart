// file: lib/src/features/dashboard/services/nutrition_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionRepository {
  NutritionRepository._();
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Calculate weight (grams) and nutrition for a given food JSON, unit and amount.
  ///
  /// foodJson expected shape (example):
  /// {
  ///   "id": 501,
  ///   "name": "Milk (Cow, full fat)",
  ///   "base_weight_gram": 100,
  ///   "measures": { "gram":100, "ml":100, "cup":250, ... },
  ///   "nutrition_per_100g": { "calories":64, "protein":3.3, "carbs":4.8, "fat":3.5 }
  /// }
  ///
  /// Returns a map:
  /// {
  ///   "weight_grams": 250.0,
  ///   "calories": 160.0,
  ///   "protein": 8.25,
  ///   "carbs": 12.0,
  ///   "fat": 8.75
  /// }
  static Map<String, dynamic> calculateNutritionFromFood({
    required Map<String, dynamic> foodJson,
    required String unit,
    required num amount,
  }) {
    // defensive getter helpers
    num _toNum(dynamic v, [num fallback = 0]) {
      if (v == null) return fallback;
      if (v is num) return v;
      if (v is String) return num.tryParse(v.replaceAll(',', '')) ?? fallback;
      return fallback;
    }

    // measures may be Map<String, dynamic>
    final measuresRaw = foodJson['measures'];
    double measureValue = 0.0;

    if (measuresRaw is Map) {
      final dynamic found = measuresRaw[unit];
      if (found != null) {
        measureValue = _toNum(found, 0).toDouble();
      }
    }

    // fallback to base_weight_gram if measure missing or zero
    final baseWeight = _toNum(foodJson['base_weight_gram'], 0).toDouble();
    if (measureValue <= 0) {
      // if unit is "gram" and measures didn't provide it, use 1 gram per unit
      if (unit.toLowerCase() == 'gram' || unit.toLowerCase() == 'g') {
        measureValue = 1.0;
      } else if (baseWeight > 0) {
        measureValue = baseWeight;
      } else {
        // last fallback: 100g
        measureValue = 100.0;
      }
    }

    final weightGrams = measureValue * amount;

    // nutrition_per_100g
    final nut = foodJson['nutrition_per_100g'];
    num cal100 = 0, prot100 = 0, carbs100 = 0, fat100 = 0;
    if (nut is Map) {
      cal100 = _toNum(nut['calories'], 0);
      prot100 = _toNum(nut['protein'], 0);
      carbs100 = _toNum(nut['carbs'], 0);
      fat100 = _toNum(nut['fat'], 0);
    } else {
      // Support flat keys on root (legacy)
      cal100 = _toNum(foodJson['calories'] ?? foodJson['kcal'] ?? 0, 0);
      prot100 = _toNum(foodJson['protein'] ?? 0, 0);
      carbs100 = _toNum(foodJson['carbs'] ?? 0, 0);
      fat100 = _toNum(foodJson['fat'] ?? 0, 0);
      // If these are per item rather than per 100g, we cannot be sure.
    }

    final factor = weightGrams / 100.0;

    final calories = (cal100 * factor).toDouble();
    final protein = (prot100 * factor).toDouble();
    final carbs = (carbs100 * factor).toDouble();
    final fat = (fat100 * factor).toDouble();

    return {
      'weight_grams': double.parse(weightGrams.toStringAsFixed(3)),
      'calories': double.parse(calories.toStringAsFixed(2)),
      'protein': double.parse(protein.toStringAsFixed(2)),
      'carbs': double.parse(carbs.toStringAsFixed(2)),
      'fat': double.parse(fat.toStringAsFixed(2)),
    };
  }

  /// Save a new meal item to Firestore, returns the created DocumentReference on success.
  ///
  /// Path: users/{uid}/meals/{date}/{mealName}/{autoId}
  /// The [date] must be in YYYY-MM-DD format (e.g. '2025-11-15').
  ///
  /// [foodJson] is the food object (see calculateNutritionFromFood).
  /// [unit] and [amount] describe the serving chosen by user.
  static Future<DocumentReference?> saveMealItem({
    required String uid,
    required String date,
    required String mealName,
    required Map<String, dynamic> foodJson,
    required String unit,
    required num amount,
    Map<String, dynamic>? extraFields, // optional: store UI fields if needed
  }) async {
    try {
      final calc = calculateNutritionFromFood(foodJson: foodJson, unit: unit, amount: amount);

      final itemId = (foodJson['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString());

      final doc = <String, dynamic>{
        'food_id': foodJson['id'] ?? itemId,
        'id': itemId, // keep original id as well if present
        'name': foodJson['name'] ?? '',
        'unit': unit,
        'amount': amount,
        'weight_grams': calc['weight_grams'],
        'calories': calc['calories'],
        'protein': calc['protein'],
        'carbs': calc['carbs'],
        'fat': calc['fat'],
        'measures': foodJson['measures'] ?? {},
        'base_weight_gram': foodJson['base_weight_gram'] ?? null,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // merge optional extras
      if (extraFields != null && extraFields.isNotEmpty) {
        doc.addAll(extraFields);
      }

      final ref = await _db
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(date)
          .collection(mealName)
          .add(doc);

      return ref;
    } catch (e, st) {
      // Consider logging error to crashlytics if available
      // debugPrint('saveMealItem error: $e\n$st');
      return null;
    }
  }

  /// Update an existing meal item (docId) under the given path.
  /// You can update quantity/unit or entirely replace nutrition.
  static Future<bool> updateMealItem({
    required String uid,
    required String date,
    required String mealName,
    required String docId,
    Map<String, dynamic>? updatedFields, // if you already have computed nutrition, supply those keys
    Map<String, dynamic>? foodJson, // optionally supply a new foodJson to recompute nutrition
    String? unit,
    num? amount,
  }) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(date)
          .collection(mealName)
          .doc(docId);

      final Map<String, dynamic> payload = {};

      if (foodJson != null && unit != null && amount != null) {
        final calc = calculateNutritionFromFood(foodJson: foodJson, unit: unit, amount: amount);
        payload.addAll({
          'food_id': foodJson['id'] ?? payload['food_id'],
          'name': foodJson['name'] ?? payload['name'],
          'unit': unit,
          'amount': amount,
          'weight_grams': calc['weight_grams'],
          'calories': calc['calories'],
          'protein': calc['protein'],
          'carbs': calc['carbs'],
          'fat': calc['fat'],
          'measures': foodJson['measures'] ?? {},
          'base_weight_gram': foodJson['base_weight_gram'] ?? null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (updatedFields != null && updatedFields.isNotEmpty) {
        payload.addAll(updatedFields);
        payload['updatedAt'] = FieldValue.serverTimestamp();
      }

      if (payload.isEmpty) return false;

      await docRef.update(payload);
      return true;
    } catch (e) {
      // debugPrint('updateMealItem error: $e');
      return false;
    }
  }

  /// Delete a meal item by docId
  static Future<bool> deleteMealItem(
      String uid, String date, String mealName, String docId) async {
    try {
      final docRef = _db
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(date)
          .collection(mealName)
          .doc(docId);
      await docRef.delete();
      return true;
    } catch (e) {
      // debugPrint('deleteMealItem error: $e');
      return false;
    }
  }

  /// Read all items for a meal (non-stream, one-time)
  static Future<List<Map<String, dynamic>>> getMealItems({
    required String uid,
    required String date,
    required String mealName,
  }) async {
    try {
      final col = _db
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(date)
          .collection(mealName);

      final snap = await col.get();
      return snap.docs.map((d) {
        final m = d.data();
        m['_docId'] = d.id;
        return m;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Convenience: Convert a Firestore document (map) to a strongly-typed preview map
  /// used by UI (makes types predictable)
  static Map<String, dynamic> normalizeStoredMeal(Map<String, dynamic> data) {
    num _toNum(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v;
      if (v is String) return num.tryParse(v.replaceAll(',', '')) ?? 0;
      return 0;
    }

    return {
      'food_id': data['food_id'],
      'name': data['name'] ?? '',
      'unit': data['unit'] ?? '',
      'amount': data['amount'] ?? 0,
      'weight_grams': (_toNum(data['weight_grams'])).toDouble(),
      'calories': (_toNum(data['calories'])).toDouble(),
      'protein': (_toNum(data['protein'])).toDouble(),
      'carbs': (_toNum(data['carbs'])).toDouble(),
      'fat': (_toNum(data['fat'])).toDouble(),
      'timestamp': data['timestamp'],
    };
  }
}
