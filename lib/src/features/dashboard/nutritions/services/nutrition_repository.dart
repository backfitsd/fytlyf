import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionRepository {
  static final _firestore = FirebaseFirestore.instance;

  /// Save a meal item under user/{uid}/meals/{date}/{mealName}
  static Future<void> saveMealItem(
      String mealName,
      Map<String, dynamic> data, {
        required String uid,
        required String date,
      }) async {
    final ref = _firestore
        .collection('users')
        .doc(uid)
        .collection('meals')
        .doc(date)
        .collection(mealName);

    await ref.add(data);
  }

  /// Save custom food under user/{uid}/customFoods
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

  /// Save water intake under user/{uid}/water_logs/{date}
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
    });
  }
}
