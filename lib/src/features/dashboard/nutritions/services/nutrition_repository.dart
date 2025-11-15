// file: lib/src/features/dashboard/nutritions/services/nutrition_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionRepository {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // =============================================================
  // SAVE A MEAL ITEM (NEW STORAGE FORMAT)
  //
  // Firestore Path:
  // users/{uid}/meals/{YYYY-MM-DD}/{mealName}/{autoDoc}
  //
  // Stored Fields (ONLY):
  //  id          →  food id from JSON
  //  unit        →  "g", "cup", "ml", "tbsp", etc.
  //  amount      →  how many units the user selected
  //  gram_weight →  total grams after conversion
  //  added_at    →  timestamp
  // =============================================================
  static Future<void> saveMealItem(
      String mealName,
      Map<String, dynamic> data, {
        required String uid,
        required String date,
      }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(date)
        .collection(mealName)
        .add({
      "id": data["id"],
      "unit": data["unit"],
      "amount": data["amount"],
      "gram_weight": data["gram_weight"],
      "added_at": FieldValue.serverTimestamp(),
    });
  }

  // =============================================================
  // UPDATE EXISTING MEAL ITEM
  // (Same minimal structure — no calories/protein stored)
  // =============================================================
  static Future<void> updateMealItem(
      String uid,
      String date,
      String mealName,
      String docId,
      Map<String, dynamic> data,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(date)
        .collection(mealName)
        .doc(docId)
        .update({
      "id": data["id"],
      "unit": data["unit"],
      "amount": data["amount"],
      "gram_weight": data["gram_weight"],
      "added_at": FieldValue.serverTimestamp(),
    });
  }

  // =============================================================
  // DELETE MEAL ITEM
  // =============================================================
  static Future<void> deleteMealItem(
      String uid,
      String date,
      String mealName,
      String docId,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(date)
        .collection(mealName)
        .doc(docId)
        .delete();
  }

  // =============================================================
  // FETCH ALL MEAL ITEMS FOR A DATE
  //
  // Returns raw minimal data only.
  // UI / calculations must compute nutrition from JSON file.
  // =============================================================
  static Future<Map<String, List<Map<String, dynamic>>>> fetchMealsForDate(
      String uid,
      String date,
      ) async {
    final result = <String, List<Map<String, dynamic>>>{};

    const meals = [
      'Breakfast',
      'Morning Snack',
      'Lunch',
      'Evening Snack',
      'Dinner',
      'Others',
    ];

    for (final meal in meals) {
      final snap = await _firestore
          .collection('users')
          .doc(uid)
          .collection('meals')
          .doc(date)
          .collection(meal)
          .get();

      result[meal] = snap.docs.map((doc) {
        final m = doc.data();
        m["docId"] = doc.id; // For editing/deleting
        return m;
      }).toList();
    }

    return result;
  }

  // =============================================================
  // SAVE CUSTOM FOOD (unchanged)
  // =============================================================
  static Future<void> saveCustomFood(
      String uid,
      Map<String, dynamic> data,
      ) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('customFoods')
        .add(data);
  }

  // =============================================================
  // FETCH CUSTOM FOODS
  // =============================================================
  static Future<List<Map<String, dynamic>>> fetchCustomFoods(String uid) async {
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('customFoods')
        .get();

    return snap.docs.map((doc) {
      final m = doc.data();
      m["id"] = doc.id;
      return m;
    }).toList();
  }

  // =============================================================
  // WATER LOG SAVE
  // =============================================================
  static Future<void> saveWaterIntake({
    required String uid,
    required String date,
    required double amount,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('water_logs')
        .doc(date)
        .set({
      "amount": amount,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // =============================================================
  // WATER LOG FETCH
  // =============================================================
  static Future<double> fetchWaterIntake({
    required String uid,
    required String date,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('water_logs')
        .doc(date)
        .get();

    if (!doc.exists) return 0;
    return (doc.data()?["amount"] ?? 0).toDouble();
  }
}
