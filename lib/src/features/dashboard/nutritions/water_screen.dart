// file: lib/src/features/dashboard/nutritions/water_screen.dart
// PREMIUM HYDRATION SCREEN – APPLE FITNESS STYLE
// Perfectly matched with your WaterRepository signatures.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/water_repository.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({Key? key}) : super(key: key);

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late AnimationController _controller;

  int totalMl = 0;
  int goalMl = 2500; // UI goal (adjust if needed)
  List<int> entries = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadToday();
    });
  }

  // yyyy-MM-dd
  String _dateKey(DateTime dt) {
    return WaterRepository.dateId(dt);
  }

  Future<void> _loadToday() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId = _dateKey(DateTime.now());

    try {
      final list = await WaterRepository.getDate(uid, dateId);
      setState(() {
        entries = list;
        totalMl = list.fold(0, (p, e) => p + e);
        loading = false;
      });
      _controller.forward();
    } catch (e) {
      debugPrint("Failed loading water: $e");
      setState(() => loading = false);
    }
  }

  // -----------------------------
  // FIXED ADD → matches repo: (uid, ml)
  // -----------------------------
  Future<void> _addEntry(int ml) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await WaterRepository.addWater(uid, ml);
      await _loadToday();
    } catch (e) {
      debugPrint("add entry failed: $e");
    }
  }

  // -----------------------------
  // FIXED REMOVE → (uid, index, dateId)
  // -----------------------------
  Future<void> _deleteEntry(int index) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId = _dateKey(DateTime.now());

    try {
      await WaterRepository.removeWater(uid, index, dateId);
      await _loadToday();
    } catch (e) {
      debugPrint("delete entry failed: $e");
    }
  }

  // -----------------------------
  // FIXED EDIT → (uid, index, newMl, dateId)
  // -----------------------------
  Future<void> _editEntry(int index, int newMl) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final dateId = _dateKey(DateTime.now());

    try {
      await WaterRepository.editWater(uid, index, newMl, dateId);
      await _loadToday();
    } catch (e) {
      debugPrint("edit entry failed: $e");
    }
  }

  // -----------------------------
  // Custom Apple-Style Picker
  // -----------------------------
  Future<void> _openCustomPicker() async {
    int selected = 250;
    const int step = 10;
    const int max = 1000;

    final controller =
    FixedExtentScrollController(initialItem: selected ~/ step);

    final result = await showDialog<int>(
      context: context,
      builder: (_) {
        final size = MediaQuery.of(context).size;

        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(builder: (_, setPop) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Add Water",
                      style: TextStyle(
                          fontSize: size.width * 0.055,
                          fontWeight: FontWeight.w800)),
                  SizedBox(height: size.height * 0.015),
                  SizedBox(
                    height: size.height * 0.18,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: size.height * 0.035,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        setPop(() => selected = i * step);
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: (max ~/ step) + 1,
                        builder: (_, i) {
                          final v = i * step;
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 150),
                            style: TextStyle(
                              fontSize: v == selected
                                  ? size.width * 0.06
                                  : size.width * 0.045,
                              fontWeight: v == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: v == selected
                                  ? Colors.blueAccent
                                  : Colors.black45,
                            ),
                            child: Text("$v ml"),
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 12),
                    ),
                    child: const Text("Add",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  )
                ],
              );
            }),
          ),
        );
      },
    );

    if (result != null) {
      _addEntry(result);
    }
  }

  // -----------------------------
  // Apple Fitness Style Hydration Ring
  // -----------------------------
  Widget _buildRing() {
    final progress = (totalMl / goalMl).clamp(0.0, 1.0);

    final size = MediaQuery.of(context).size.width * 0.55;
    final ringWidth = size * 0.08;

    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          return CustomPaint(
            painter: _RingPainter(
              progress: _controller.value * progress,
              ringWidth: ringWidth,
              baseColor: Colors.grey.shade200,
              ringColor: Colors.blueAccent,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded,
                      color: Colors.blueAccent,
                      size: size * 0.22),
                  Text(
                    "$totalMl ml",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: size * 0.18),
                  ),
                  Text(
                    "Goal: $goalMl ml",
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: size * 0.065),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // -----------------------------
  // Entry Card
  // -----------------------------
  Widget _entryCard(int ml, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blueAccent.withOpacity(0.12),
            child: const Icon(Icons.water_drop, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$ml ml",
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () => _deleteEntry(index),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          )
        ],
      ),
    );
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Hydration"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildRing(),
            const SizedBox(height: 20),

            const Text(
              "Hydration",
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text("Keep pushing toward your goal!",
                style: TextStyle(color: Colors.black54)),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _quickAdd(100),
                _quickAdd(250),
                _quickAdd(500),
              ],
            ),

            const SizedBox(height: 12),

            _customAddButton(),

            const SizedBox(height: 22),

            Align(
              alignment: Alignment.centerLeft,
              child: Text("Entries",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ),
            const SizedBox(height: 10),

            entries.isEmpty
                ? const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Text("No water added.",
                  style: TextStyle(
                      color: Colors.black38, fontSize: 15)),
            )
                : Column(
              children: List.generate(
                  entries.length,
                      (i) => _entryCard(entries[i], i)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // -----------------------------
  // Quick Add
  // -----------------------------
  Widget _quickAdd(int ml) {
    return ElevatedButton(
      onPressed: () => _addEntry(ml),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: Text("$ml ml",
          style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _customAddButton() {
    return ElevatedButton.icon(
      onPressed: _openCustomPicker,
      icon: const Icon(Icons.add_circle_outline, color: Colors.blueAccent),
      label: const Text("Custom"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;

  _RingPainter({
    required this.progress,
    required this.ringWidth,
    required this.ringColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - ringWidth) / 2;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = baseColor;
    canvas.drawCircle(center, radius, basePaint);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = ringColor;

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        arcPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
