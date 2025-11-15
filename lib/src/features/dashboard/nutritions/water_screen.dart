// file: lib/src/features/dashboard/nutritions/water/water_screen.dart
// Premium Modern Water Tracker (UI Option B) + Firestore Structure Option 2

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({Key? key}) : super(key: key);

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int totalMl = 0;
  int targetMl = 3000;

  bool loading = true;

  late AnimationController _waveController;

  List<Map<String, dynamic>> logs = [];

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _listenToWaterLogs();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  /// Format date as YYYY-MM-DD string
  String _dateKey(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  /// Live listener for today's water logs
  void _listenToWaterLogs() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today = _dateKey(DateTime.now());

    _db
        .collection('users')
        .doc(uid)
        .collection('water')
        .doc(today)
        .collection('logs')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      logs = [];
      totalMl = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amount = (data['amount_ml'] ?? 0) as int;

        logs.add({
          "id": doc.id,
          "amount_ml": amount,
          "timestamp": data['timestamp'],
        });

        totalMl += amount;
      }

      setState(() => loading = false);
    });
  }

  /// Add water entry
  Future<void> _addWater(int amount) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final today = _dateKey(DateTime.now());
    final col = _db
        .collection('users')
        .doc(uid)
        .collection('water')
        .doc(today)
        .collection('logs');

    await col.add({
      "amount_ml": amount,
      "timestamp": DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Undo: deletes last log
  Future<void> _undoLast() async {
    if (logs.isEmpty) return;

    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final last = logs.last;
    final today = _dateKey(DateTime.now());

    await _db
        .collection('users')
        .doc(uid)
        .collection('water')
        .doc(today)
        .collection('logs')
        .doc(last["id"])
        .delete();
  }

  double _progress() {
    if (targetMl == 0) return 0;
    return (totalMl / targetMl).clamp(0.0, 1.0);
  }

  Color _progressColor() {
    final p = _progress();

    if (p < 0.3) return Colors.lightBlueAccent;
    if (p < 0.7) return Colors.blueAccent;
    if (p <= 1.0) return Colors.indigo;
    return Colors.indigo.shade900;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress();
    final waveColor = _progressColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Hydration"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Premium Glass Fill Water Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Today’s Water Intake",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Animated Water Glass
                  SizedBox(
                    height: 320,
                    width: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: WaterGlassPainter(
                            progress: progress,
                            waveAnimation: _waveController.value,
                            waveColor: waveColor,
                          ),
                          size: const Size(200, 300),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  Text(
                    "$totalMl / $targetMl ml",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    progress >= 1.0 ? "Goal Achieved 🎉" : "Keep Hydrated 💧",
                    style: TextStyle(
                      fontSize: 15,
                      color: progress >= 1.0
                          ? Colors.green
                          : Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Quick Add Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickAddButton("250 ml", 250),
                _quickAddButton("500 ml", 500),
                _quickAddButton("1 L", 1000),
              ],
            ),

            const SizedBox(height: 18),

            // Undo button
            if (logs.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _undoLast,
                  icon: const Icon(Icons.undo),
                  label: const Text("Undo Last Entry"),
                ),
              ),

            if (logs.isEmpty)
              const Text(
                "No entries yet. Start by adding water!",
                style: TextStyle(color: Colors.black54),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickAddButton(String label, int amount) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => _addWater(amount),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade50,
          foregroundColor: Colors.blue.shade900,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label),
        ),
      ),
    );
  }
}

/// Painter for Premium Water Glass Animation
class WaterGlassPainter extends CustomPainter {
  final double progress;
  final double waveAnimation;
  final Color waveColor;

  WaterGlassPainter({
    required this.progress,
    required this.waveAnimation,
    required this.waveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintGlass = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final rect = Rect.fromLTWH(20, 10, size.width - 40, size.height - 20);

    // Draw outer glass
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(30)),
      paintGlass,
    );

    // Draw water fill
    final fillLevel = rect.bottom - (rect.height * progress);

    final path = Path();

    const waveHeight = 12.0;
    final double waveSpeed = waveAnimation * 2 * pi;

    path.moveTo(rect.left, fillLevel);

    for (double x = rect.left; x <= rect.right; x++) {
      final y = sin((x / rect.width * 2 * pi) + waveSpeed) * waveHeight;

      path.lineTo(x, fillLevel + y);
    }

    path.lineTo(rect.right, rect.bottom);
    path.lineTo(rect.left, rect.bottom);
    path.close();

    final waterPaint = Paint()
      ..color = waveColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, waterPaint);
  }

  @override
  bool shouldRepaint(covariant WaterGlassPainter old) {
    return old.progress != progress ||
        old.waveAnimation != waveAnimation ||
        old.waveColor != waveColor;
  }
}
