import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WaterRepository {
  static final _fire = FirebaseFirestore.instance;

  static String _dateId(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  static DocumentReference _doc(String uid, DateTime d) =>
      _fire.collection('users').doc(uid)
          .collection('water').doc(_dateId(d));

  // -----------------------------
  // ADD WATER (VERY MINIMAL)
  // -----------------------------
  static Future<void> addWater(String uid, int ml) async {
    final now = DateTime.now();
    final d = _doc(uid, now);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(d);

      if (!snap.exists) {
        tx.set(d, {
          "total": ml,
          "entries": [ml]
        });
      } else {
        final data = snap.data()!;
        final list = List<int>.from(data["entries"]);
        final total = data["total"] ?? 0;

        list.add(ml);

        tx.update(d, {
          "entries": list,
          "total": total + ml,
        });
      }
    });
  }

  // -----------------------------
  // REMOVE WATER ENTRY (BY INDEX)
  // -----------------------------
  static Future<void> removeWater(
      String uid, int index, DateTime date) async {

    final d = _doc(uid, date);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(d);
      if (!snap.exists) return;

      final data = snap.data()!;
      final list = List<int>.from(data["entries"]);
      final total = data["total"] ?? 0;

      final removed = list[index];
      list.removeAt(index);

      tx.update(d, {
        "entries": list,
        "total": total - removed,
      });
    });
  }

  // -----------------------------
  // EDIT WATER ENTRY (BY INDEX)
  // -----------------------------
  static Future<void> editWater(
      String uid, int index, int newMl, DateTime date) async {

    final d = _doc(uid, date);

    await _fire.runTransaction((tx) async {
      final snap = await tx.get(d);
      if (!snap.exists) return;

      final data = snap.data()!;
      final list = List<int>.from(data["entries"]);
      final total = data["total"] ?? 0;

      final old = list[index];
      list[index] = newMl;

      tx.update(d, {
        "entries": list,
        "total": total - old + newMl,
      });
    });
  }

  // -----------------------------
  // GET TODAY
  // -----------------------------
  static Future<Map<String, dynamic>?> getToday(String uid) async {
    final snap = await _doc(uid, DateTime.now()).get();
    return snap.exists ? snap.data() : null;
  }

  // -----------------------------
  // GET YESTERDAY
  // -----------------------------
  static Future<Map<String, dynamic>?> getYesterday(String uid) async {
    final snap = await _doc(uid,
        DateTime.now().subtract(Duration(days: 1)))
        .get();
    return snap.exists ? snap.data() : null;
  }
}
