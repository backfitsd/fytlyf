import 'dart:math';
import 'package:flutter/material.dart';

class WaterScreen extends StatefulWidget {
  final double initialWater;
  final double goalWater;

  const WaterScreen({
    Key? key,
    this.initialWater = 0.0,
    this.goalWater = 2.5,
  }) : super(key: key);

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  late double _currentWater;
  late final double _goal;

  final List<_WaterLog> _logs = [];

  static const LinearGradient _appGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _currentWater = widget.initialWater;
    _goal = widget.goalWater;

    if (_currentWater > 0) {
      _logs.insert(
        0,
        _WaterLog(amount: _currentWater, time: DateTime.now()),
      );
    }
  }

  void _addWater(double liters) {
    setState(() {
      _currentWater += liters;
      if (_currentWater > _goal) _currentWater = _goal;

      _logs.insert(0, _WaterLog(amount: liters, time: DateTime.now()));
    });
  }

  void _openPicker() {
    double tempWater = 0.25; // liters
    int selected = 250;
    const int step = 50;

    final controller =
    FixedExtentScrollController(initialItem: selected ~/ step);

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final wheelExtent = size.height * 0.03;

        return StatefulBuilder(builder: (context, setDialog) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Water",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: wheelExtent * 3,
                    child: ListWheelScrollView.useDelegate(
                      controller: controller,
                      itemExtent: wheelExtent,
                      physics: const FixedExtentScrollPhysics(),
                      onSelectedItemChanged: (i) {
                        setDialog(() {
                          selected = i * step;
                          tempWater = selected / 1000.0;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: 30,
                        builder: (context, i) {
                          final value = i * step;
                          final selectedNow = value == selected;
                          return AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 120),
                            style: TextStyle(
                              fontSize: selectedNow ? 22 : 18,
                              fontWeight: selectedNow
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selectedNow
                                  ? Colors.blueAccent
                                  : Colors.black45,
                            ),
                            child: Text("$value ml"),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _addWater(tempWater);
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Color _progressColor(double p) {
    if (p < 0.33) return Colors.blueAccent;
    if (p < 0.66) return Colors.lightBlue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final progress = (_currentWater / _goal).clamp(0.0, 1.0);
    final ringSize = min(width * 0.58, 240.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hydration"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: ringSize,
                    width: ringSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.blueAccent.withOpacity(0.15),
                          valueColor: AlwaysStoppedAnimation(
                              _progressColor(progress)),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.water_drop_rounded,
                                size: ringSize * 0.14,
                                color: Colors.blueAccent),
                            Text("${_currentWater.toStringAsFixed(2)} L",
                                style: TextStyle(
                                    fontSize: ringSize * 0.13,
                                    fontWeight: FontWeight.w800)),
                            Text("Goal ${_goal.toStringAsFixed(1)} L",
                                style: const TextStyle(color: Colors.black54)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            /// Quick add
            Row(
              children: [
                Expanded(child: _quickAdd("100 ml", 0.1)),
                const SizedBox(width: 8),
                Expanded(child: _quickAdd("250 ml", 0.25)),
                const SizedBox(width: 8),
                Expanded(child: _quickAdd("500 ml", 0.5)),
              ],
            ),

            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: _openPicker,
              icon: const Icon(Icons.add_circle_outline,
                  color: Colors.blueAccent),
              label: const Text("Custom Amount"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 0,
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),

            const SizedBox(height: 14),

            Expanded(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Today",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _logs.isEmpty
                          ? const Center(
                          child: Text("No water intake added yet.",
                              style: TextStyle(color: Colors.black45)))
                          : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, i) {
                          final log = _logs[i];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                              Colors.blueAccent.withOpacity(0.12),
                              child: const Icon(Icons.water_drop_rounded,
                                  color: Colors.blueAccent),
                            ),
                            title: Text(
                                "${log.amount.toStringAsFixed(2)} L"),
                            subtitle: Text(
                                "${log.amount * 1000} ml added"),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAdd(String label, double liters) {
    return ElevatedButton(
      onPressed: () => _addWater(liters),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Text(label),
    );
  }
}

class _WaterLog {
  final double amount;
  final DateTime time;

  _WaterLog({required this.amount, required this.time});
}
