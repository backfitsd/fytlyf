import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WaterRepository {
  static final FirebaseFirestore _fire = FirebaseFirestore.instance;

  // Format date as yyyy-MM-dd
  static String dateId(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  // Get reference
  static DocumentReference _doc(String uid, String dateId) {
    return _fire
        .collection('users')
        .doc(uid)
        .collection('water')
        .doc(dateId);
  }

  // ---------------------------------------------------------------------------
  // ADD WATER (pure minimal model)
  // ---------------------------------------------------------------------------
  static Future<void> addWater(String uid, int ml) async {
    final id = dateId(DateTime.now());
    final docRef = _doc(uid, id);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (!snap.exists) {
        tx.set(docRef, {
          "entries": [ml],    // ONLY store integers
        });
      } else {
        final data = snap.data() as Map<String, dynamic>;
        final List<int> list = List<int>.from(
            (data["entries"] ?? []).map((e) => (e as num).toInt()));

        list.add(ml);

        tx.update(docRef, {"entries": list});
      }
    });
  }

  // ---------------------------------------------------------------------------
  // REMOVE ENTRY (by index)
  // ---------------------------------------------------------------------------
  static Future<void> removeWater(String uid, int index, String dateId) async {
    final docRef = _doc(uid, dateId);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<int> list = List<int>.from(
          (data["entries"] ?? []).map((e) => (e as num).toInt()));

      if (index < 0 || index >= list.length) return;

      list.removeAt(index);

      tx.update(docRef, {"entries": list});
    });
  }

  // ---------------------------------------------------------------------------
  // EDIT ENTRY (replace ml at index)
  // ---------------------------------------------------------------------------
  static Future<void> editWater(
      String uid, int index, int newMl, String dateId) async {

    final docRef = _doc(uid, dateId);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final List<int> list = List<int>.from(
          (data["entries"] ?? []).map((e) => (e as num).toInt()));

      if (index < 0 || index >= list.length) return;

      list[index] = newMl;

      tx.update(docRef, {"entries": list});
    });
  }

  // ---------------------------------------------------------------------------
  // GET A SPECIFIC DATE (return empty list if no data → total is 0)
  // ---------------------------------------------------------------------------
  static Future<List<int>> getDate(String uid, String dateId) async {
    final snap = await _doc(uid, dateId).get();

    if (!snap.exists) return [];

    final data = snap.data() as Map<String, dynamic>;

    final entries = data["entries"];

    if (entries == null) return [];

    return List<int>.from(entries.map((e) => (e as num).toInt()));
  }

  // ---------------------------------------------------------------------------
  // GET DATE RANGE (always return total for each day)
  // If no document → return 0 for that day.
  // ---------------------------------------------------------------------------
  static Future<Map<String, int>> getRange(
      String uid, DateTime startDate, DateTime endDate) async {

    final result = <String, int>{};
    DateTime current = startDate;

    while (!current.isAfter(endDate)) {
      final id = dateId(current);
      final entries = await getDate(uid, id);
      final total = entries.fold(0, (sum, ml) => sum + ml);
      result[id] = total; // If no data → total = 0
      current = current.add(const Duration(days: 1));
    }

    return result;
  }
}
