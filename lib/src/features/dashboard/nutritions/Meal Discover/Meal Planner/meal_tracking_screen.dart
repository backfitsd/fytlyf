// OPTIMIZED MEAL TRACKING (Option 2) — FIXED IMPORTS FOR “Meal Discover”

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fytlyf/src/features/dashboard/nutritions/services/nutrition_repository.dart' show NutritionRepository;
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lib/src/features/dashboard/nutritions/services/nutrition_database.dart';
import '../../../services/nutrition_repository.dart';

import 'search_meal_screen.dart';
import 'meal_info_screen.dart';

class NutritionModel extends ChangeNotifier {
  NutritionModel._internal();
  static final NutritionModel instance = NutritionModel._internal();

  int totalKcal = 2500;
  int consumedKcal = 0;
  double protCurrent = 0, protTarget = 70;
  double carbsCurrent = 0, carbsTarget = 250;
  double fatCurrent = 0, fatTarget = 120;

  void addMacros({required int kcal, double prot = 0, double carbs = 0, double fat = 0}) {
    consumedKcal += kcal;
    protCurrent += prot;
    carbsCurrent += carbs;
    fatCurrent += fat;
    notifyListeners();
  }

  void removeMacros({required int kcal, double prot = 0, double carbs = 0, double fat = 0}) {
    consumedKcal -= kcal;
    protCurrent -= prot;
    carbsCurrent -= carbs;
    fatCurrent -= fat;
    notifyListeners();
  }
}

class _FoodItem {
  String id;
  String name;
  String serving;
  int kcal;
  double protein;
  double carbs;
  double fat;

  _FoodItem({
    required this.id,
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class _MealSection {
  final String name;
  final int target;
  int consumed;
  _MealSection({required this.name, required this.consumed, required this.target});
}

class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({super.key});

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFFFA726);
  static const Color _bg = Color(0xFFF4F7FB);

  final List<_MealSection> sections = [
    _MealSection(name: 'Breakfast', consumed: 0, target: 675),
    _MealSection(name: 'Morning Snack', consumed: 0, target: 330),
    _MealSection(name: 'Lunch', consumed: 0, target: 375),
    _MealSection(name: 'Evening Snack', consumed: 0, target: 100),
    _MealSection(name: 'Dinner', consumed: 0, target: 400),
    _MealSection(name: 'Others', consumed: 0, target: 0),
  ];

  Map<String, List<_FoodItem>> _mealItems = {
    'Breakfast': [],
    'Morning Snack': [],
    'Lunch': [],
    'Evening Snack': [],
    'Dinner': [],
    'Others': [],
  };

  int? _openIndex;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _openSearchAndAdd(String mealName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchMealScreen()),
    );
    if (result == null) return;

    final double servings = 1.0;

    int kcal = (result["calories"] * servings).round();
    double prot = (result["protein"] ?? 0).toDouble();
    double carbs = (result["carbs"] ?? 0).toDouble();
    double fat = (result["fat"] ?? 0).toDouble();

    final item = _FoodItem(
      id: result["id"] ?? UniqueKey().toString(),
      name: result["name"],
      serving: result["serving"],
      kcal: kcal,
      protein: prot,
      carbs: carbs,
      fat: fat,
    );

    setState(() {
      _mealItems[mealName]!.insert(0, item);
      sections.firstWhere((s) => s.name == mealName).consumed += kcal;
      NutritionModel.instance.addMacros(kcal: kcal, prot: prot, carbs: carbs, fat: fat);
    });

    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final date = DateTime.now().toIso8601String().split("T").first;
      await NutritionRepository.saveMealItem(mealName, {
        "id": item.id,
        "name": item.name,
        "serving": item.serving,
        "calories": item.kcal,
        "protein": item.protein,
        "carbs": item.carbs,
        "fat": item.fat,
      }, uid: uid, date: date);
    }
  }

  void _addCustomItem(String mealName) {
    final nameCtrl = TextEditingController();
    final servingCtrl = TextEditingController(text: "1 serving");
    final kcalCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Custom Food"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: servingCtrl, decoration: const InputDecoration(labelText: "Serving")),
            TextField(controller: kcalCtrl, decoration: const InputDecoration(labelText: "Calories"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accent),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final serving = servingCtrl.text.trim();
              final kcal = int.tryParse(kcalCtrl.text.trim()) ?? 0;

              final item = _FoodItem(
                id: UniqueKey().toString(),
                name: name,
                serving: serving,
                kcal: kcal,
                protein: 0,
                carbs: 0,
                fat: 0,
              );

              setState(() {
                _mealItems[mealName]!.insert(0, item);
                sections.firstWhere((s) => s.name == mealName).consumed += kcal;
                NutritionModel.instance.addMacros(kcal: kcal);
              });

              final uid = _auth.currentUser?.uid;
              if (uid != null) {
                await NutritionRepository.saveCustomFood(uid, {
                  "name": name,
                  "serving": serving,
                  "calories": kcal,
                  "protein": 0,
                  "carbs": 0,
                  "fat": 0,
                });
              }

              Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _removeItem(String mealName, int index) {
    final removed = _mealItems[mealName]!.removeAt(index);

    setState(() {
      sections.firstWhere((s) => s.name == mealName).consumed -= removed.kcal;
      NutritionModel.instance.removeMacros(
        kcal: removed.kcal,
        prot: removed.protein,
        carbs: removed.carbs,
        fat: removed.fat,
      );
    });
  }

  Widget _buildMealCard(int idx, _MealSection s) {
    final isOpen = _openIndex == idx;
    final items = _mealItems[s.name]!;
    final text = s.target > 0 ? "${s.consumed} / ${s.target} Cal" : "${s.consumed} Cal";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(text),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                onTap: () => _addCustomItem(s.name),
                child: CircleAvatar(radius: 15, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.add, size: 18, color: Colors.black87)),
              ),
              const SizedBox(width: 10),
              AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: isOpen ? 0.5 : 0,
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  onPressed: () => setState(() => _openIndex = isOpen ? null : idx),
                ),
              ),
            ]),
            onTap: () => setState(() => _openIndex = isOpen ? null : idx),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ConstrainedBox(
              constraints: isOpen ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    _mealSummary(s.name, items),
                    const SizedBox(height: 10),

                    items.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text("No items added.", style: TextStyle(color: Colors.grey.shade600)),
                    )
                        : Column(
                      children: items.asMap().entries.map((e) {
                        final i = e.key;
                        final it = e.value;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ListTile(
                            title: Text(it.name),
                            subtitle: Text(it.serving),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              Text("${it.kcal} Cal", style: const TextStyle(fontWeight: FontWeight.w700)),
                              PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == "delete") _removeItem(s.name, i);
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(value: "delete", child: Text("Delete", style: TextStyle(color: Colors.red))),
                                ],
                              )
                            ]),
                          ),
                        );
                      }).toList(),
                    ),

                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text("Add from DB"),
                          onPressed: () => _openSearchAndAdd(s.name),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: _accent),
                        onPressed: () => _addCustomItem(s.name),
                        child: const Text("Custom"),
                      ),
                    ]),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealSummary(String mealName, List<_FoodItem> items) {
    final totalKcal = items.fold<int>(0, (p, e) => p + e.kcal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        SizedBox(
          height: 60,
          width: 60,
          child: CustomPaint(
            painter: _SolidRingPainterMock(
              progress: min(1.0, totalKcal / 800),
              ringWidth: 7,
              ringColor: _accent,
              baseColor: const Color(0xFFF7EFE6),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text("$totalKcal kcal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = NutritionModel.instance;
    final progress = model.totalKcal == 0 ? 0.0 : model.consumedKcal / model.totalKcal;

    final now = DateTime.now();
    final headerDate = "Today, ${_monthName(now.month)} ${now.day}";

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(children: [
              const Text("Track Meal", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 14),
                  const SizedBox(width: 6),
                  Text(headerDate),
                ]),
              )
            ]),

            const SizedBox(height: 18),

            _topCalorieCard(model.consumedKcal, model.totalKcal, progress),

            const SizedBox(height: 18),

            ...sections.asMap().entries.map((e) => _buildMealCard(e.key, e.value)).toList(),

            const SizedBox(height: 50),
          ]),
        ),
      ),
    );
  }

  Widget _topCalorieCard(int consumed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        SizedBox(
          height: 80,
          width: 80,
          child: CustomPaint(
            painter: _RingPainter(progress: progress, strokeWidth: 8, colors: const [Color(0xFFFFA726), Color(0xFFFF8A00)]),
          ),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("$consumed of $total Cal", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Keep going — every meal matters"),
        ]),
      ]),
    );
  }

  String _monthName(int m) {
    const list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
    return list[m - 1];
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  _RingPainter({required this.progress, required this.strokeWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = (size.width/2) - strokeWidth/2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade300;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi/2,
        endAngle: -pi/2 + (2 * pi * progress),
        colors: colors,
      ).createShader(rect);

    canvas.drawArc(rect, -pi/2, 2 * pi * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress;
}

class _SolidRingPainterMock extends CustomPainter {
  final double progress;
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;

  _SolidRingPainterMock({
    required this.progress,
    required this.ringWidth,
    required this.ringColor,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = (min(size.width, size.height) - ringWidth) / 2;

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..color = baseColor;

    canvas.drawCircle(center, radius, base);

    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth
      ..strokeCap = StrokeCap.round
      ..color = ringColor;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, 2 * pi * progress, false, prog);
  }

  @override
  bool shouldRepaint(covariant _SolidRingPainterMock oldDelegate) => oldDelegate.progress != progress;
}
