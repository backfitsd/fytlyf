// file: lib/src/features/dashboard/nutritions/Meal Discover/Meal Planner/meal_tracking_screen.dart
// Cleaned & Firestore-integrated MealTrackingScreen (uses compact Firestore format + local JSON)
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

import '../../services/nutrition_database.dart';
import '../../services/nutrition_repository.dart';
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

  void setTotals({
    required int consumed,
    required int total,
    required double prot,
    required double carbs,
    required double fat,
  }) {
    consumedKcal = consumed;
    totalKcal = total;
    protCurrent = prot;
    carbsCurrent = carbs;
    fatCurrent = fat;
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
  String? docId;

  _FoodItem({
    required this.id,
    required this.name,
    required this.serving,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.docId,
  });
}

class _MealSection {
  final String name;
  final int target;
  int consumed;
  _MealSection({
    required this.name,
    required this.consumed,
    required this.target,
  });
}

class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen>
    with TickerProviderStateMixin {
  static const Color _accent = Color(0xFFFFA726);
  static const Color _bg = Color(0xFFF4F7FB);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  late DateTime _selectedDateTime;
  late String _selectedDate; // YYYY-MM-DD
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDateTime = DateTime.now();
    _selectedDate = _formatDate(_selectedDateTime);

    // initialize nutrition DB (safe if already called elsewhere)
    NutritionDatabase.init().catchError((_) {});

    _loadMealsForDate(_selectedDate);
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _monthName(int m) {
    const list = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return list[m - 1];
  }

  bool _isEditableDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sel = DateTime(_selectedDateTime.year, _selectedDateTime.month,
        _selectedDateTime.day);
    final diff = today.difference(sel).inDays;
    // editable for today & yesterday only
    return diff == 0 || diff == 1;
  }

  Map<String, dynamic>? _findFoodJsonById(dynamic idValue) {
    if (idValue == null) return null;
    // ids in json might be number or string; normalize both to string for compare
    final idStr = idValue.toString();
    for (final item in NutritionDatabase.all) {
      try {
        final candidateId = (item['id'] ?? '').toString();
        if (candidateId == idStr) return Map<String, dynamic>.from(item);
      } catch (_) {}
    }
    return null;
  }

  // Compute nutrition for an item based on either doc fields or JSON lookup
  Map<String, dynamic> _computeNutritionFromDoc(Map<String, dynamic> data) {
    // If doc already has calories/protein/carbs/fat, use them (back-compat)
    if (data.containsKey('calories') &&
        data.containsKey('protein') &&
        data.containsKey('carbs') &&
        data.containsKey('fat')) {
      final num c = (data['calories'] ?? 0) as num;
      final num p = (data['protein'] ?? 0) as num;
      final num cb = (data['carbs'] ?? 0) as num;
      final num f = (data['fat'] ?? 0) as num;
      return {
        'calories': c.toInt(),
        'protein': (p.toDouble()),
        'carbs': (cb.toDouble()),
        'fat': (f.toDouble()),
        'servingText': data['serving']?.toString() ?? '',
      };
    }

    // New compact format: id + unit + amount + gram_weight
    // Expect gram_weight (in grams) to be present (best), else try to compute via measures map in JSON using unit+amount
    final id = data['id'];
    final unit = (data['unit'] ?? '').toString(); // gram, ml, cup, piece, tablespoon...
    final amount = (data['amount'] ?? 0) as num;
    double gramWeight = 0.0;

    // If user saved gram_weight directly (preferred)
    if (data.containsKey('gram_weight')) {
      gramWeight = (data['gram_weight'] ?? 0).toDouble();
    } else {
      // try to resolve from JSON measures: find food json and map unit -> measures[unit] * amount
      final foodJson = _findFoodJsonById(id);
      if (foodJson != null) {
        final measures = (foodJson['measures'] ?? <String, dynamic>{}) as Map;
        // The JSON we designed stores grams for each measure, e.g. "cup": 250, "gram":100 etc.
        if (measures.containsKey(unit)) {
          try {
            final base = measures[unit];
            gramWeight = (base is num) ? base.toDouble() * amount.toDouble() : double.tryParse(base.toString()) ?? 0.0;
            // If measures[unit] is per-100g base (like gram:100), we've stored exact gram values per measure in your spec,
            // so multiplying by amount is correct (e.g., amount=1 cup -> base=250 -> gramWeight=250)
          } catch (_) {
            gramWeight = 0.0;
          }
        } else {
          // As fallback: if measures contains 'gram' and amount is numeric and unit is like 'piece' but measures has piece -> use that
          if (measures.containsKey('gram') && unit.toLowerCase() == 'gram') {
            final base = measures['gram'];
            gramWeight = (base is num) ? base.toDouble() * amount.toDouble() : double.tryParse(base.toString()) ?? 0.0;
          } else {
            // try 'piece' mapping or 'ml' mapping fallback
            if (measures.containsKey(unit)) {
              final base = measures[unit];
              gramWeight = (base is num) ? base.toDouble() * amount.toDouble() : double.tryParse(base.toString()) ?? 0.0;
            } else {
              // last fallback: if unit empty and data.quantity exists, show quantity but gramWeight 0
              gramWeight = 0.0;
            }
          }
        }
      } else {
        gramWeight = 0.0;
      }
    }

    // Compose servingText
    String servingText;
    if ((unit.isNotEmpty) && (amount != 0)) {
      // e.g., "1 cup (250 g)" or "50 g"
      if (gramWeight > 0) {
        final g = gramWeight % 1 == 0 ? gramWeight.toInt() : double.parse(gramWeight.toStringAsFixed(1));
        servingText = "${amount.toString()} $unit (${g} g)";
      } else {
        servingText = "${amount.toString()} $unit";
      }
    } else if (data.containsKey('serving') && (data['serving'] != null)) {
      servingText = data['serving'].toString();
    } else {
      servingText = '';
    }

    // Look up nutrition_per_100g in JSON
    final foodJson = _findFoodJsonById(id);
    if (foodJson == null) {
      // cannot compute — return zeroed values but keep serving
      return {
        'calories': 0,
        'protein': 0.0,
        'carbs': 0.0,
        'fat': 0.0,
        'servingText': servingText,
      };
    }

    final nutrition = (foodJson['nutrition_per_100g'] ?? <String, dynamic>{}) as Map<String, dynamic>;
    final num cal100 = (nutrition['calories'] ?? nutrition['kcal'] ?? 0) as num;
    final num prot100 = (nutrition['protein'] ?? 0) as num;
    final num carbs100 = (nutrition['carbs'] ?? 0) as num;
    final num fat100 = (nutrition['fat'] ?? 0) as num;

    final factor = gramWeight / 100.0;
    final computedCalories = (cal100 * factor).round();
    final computedProt = double.parse((prot100 * factor).toStringAsFixed(2));
    final computedCarbs = double.parse((carbs100 * factor).toStringAsFixed(2));
    final computedFat = double.parse((fat100 * factor).toStringAsFixed(2));

    return {
      'calories': computedCalories,
      'protein': computedProt,
      'carbs': computedCarbs,
      'fat': computedFat,
      'servingText': servingText,
    };
  }

  Future<void> _loadMealsForDate(String date) async {
    setState(() {
      _loading = true;
    });

    // reset
    for (var k in _mealItems.keys) _mealItems[k] = [];
    for (var s in sections) s.consumed = 0;

    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      for (var section in sections) {
        final col = _db
            .collection('users')
            .doc(uid)
            .collection('meals')
            .doc(date)
            .collection(section.name);

        final snapshot = await col.get();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          // compute nutrition (backwards compatible)
          final nutrit = _computeNutritionFromDoc(data);

          final int kcal = (nutrit['calories'] ?? 0) is int ? nutrit['calories'] : (nutrit['calories'] ?? 0).toInt();
          final double prot = (nutrit['protein'] ?? 0).toDouble();
          final double carbs = (nutrit['carbs'] ?? 0).toDouble();
          final double fat = (nutrit['fat'] ?? 0).toDouble();
          final String servingText = (nutrit['servingText'] ?? '').toString();

          _mealItems[section.name]!.add(
            _FoodItem(
              id: data['id']?.toString() ?? '',
              name: data['name']?.toString() ?? _findFoodJsonById(data['id'])?['name']?.toString() ?? '',
              serving: servingText,
              kcal: kcal,
              protein: prot,
              carbs: carbs,
              fat: fat,
              docId: doc.id,
            ),
          );
          section.consumed += kcal;
        }
      }

      final totalConsumed =
      sections.fold<int>(0, (p, e) => p + e.consumed);
      final protSum = _mealItems.values
          .expand((l) => l)
          .fold<double>(0.0, (p, e) => p + e.protein);
      final carbsSum = _mealItems.values
          .expand((l) => l)
          .fold<double>(0.0, (p, e) => p + e.carbs);
      final fatSum = _mealItems.values
          .expand((l) => l)
          .fold<double>(0.0, (p, e) => p + e.fat);

      NutritionModel.instance.setTotals(
        consumed: totalConsumed,
        total: NutritionModel.instance.totalKcal,
        prot: protSum,
        carbs: carbsSum,
        fat: fatSum,
      );
    } catch (e) {
      debugPrint("Error loading meals: $e");
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openSearchForMeal(String mealName) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchMealScreen(preselectedMeal: mealName),
      ),
    );

    // if search returned true (added), reload
    if (res != null) {
      await _loadMealsForDate(_selectedDate);
    }
  }

  Future<void> _onEditItem(String mealName, int index) async {
    if (!_isEditableDate()) return;

    final item = _mealItems[mealName]![index];

    final args = {
      'info': {
        'id': item.id,
        'name': item.name,
        'serving': item.serving,
        // For editing we pass minimal info; MealInfoScreen will be able to handle it.
        'calories': item.kcal,
        'protein': item.protein,
        'carbs': item.carbs,
        'fat': item.fat,
      },
      'edit': true,
      'mealName': mealName,
      'date': _selectedDate,
      'docId': item.docId,
    };

    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealInfoScreen.fromEdit(args),
      ),
    );

    if (updated != null) {
      await _loadMealsForDate(_selectedDate);
    }
  }

  Future<void> _onDeleteItem(String mealName, int index) async {
    if (!_isEditableDate()) return;

    final item = _mealItems[mealName]![index];
    final uid = _auth.currentUser?.uid;

    if (uid != null && item.docId != null) {
      await NutritionRepository.deleteMealItem(
          uid, _selectedDate, mealName, item.docId!);
      await _loadMealsForDate(_selectedDate);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = now;
    final yesterday = now.subtract(const Duration(days: 1));
    final dayBefore = now.subtract(const Duration(days: 2));

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Choose date')),
              ListTile(
                title: const Text('Today'),
                onTap: () => Navigator.pop(ctx, today),
              ),
              ListTile(
                title: const Text('Yesterday'),
                onTap: () => Navigator.pop(ctx, yesterday),
              ),
              ListTile(
                title: const Text('Day before yesterday'),
                onTap: () => Navigator.pop(ctx, dayBefore),
              ),
              ListTile(
                title: const Text('Choose date...'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: _selectedDateTime,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  Navigator.pop(ctx, d);
                },
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateTime = picked;
        _selectedDate = _formatDate(picked);
      });
      await _loadMealsForDate(_selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = NutritionModel.instance;
    final progress = model.totalKcal == 0
        ? 0.0
        : model.consumedKcal / model.totalKcal;

    final headerDate =
        "${_selectedDateTime.day} ${_monthName(_selectedDateTime.month)}";

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    "Track Meal",
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 14),
                          const SizedBox(width: 6),
                          Text(headerDate),
                        ],
                      ),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 18),

              _topCalorieCard(
                  model.consumedKcal, model.totalKcal, progress),

              const SizedBox(height: 12),

              // Horizontal macro bars
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(children: [
                  _macroBar(
                      'Protein',
                      model.protCurrent.toInt(),
                      model.protTarget.toInt(),
                      const Color(0xFF42A5F5)),
                  const SizedBox(height: 8),
                  _macroBar(
                      'Carbs',
                      model.carbsCurrent.toInt(),
                      model.carbsTarget.toInt(),
                      const Color(0xFF66BB6A)),
                  const SizedBox(height: 8),
                  _macroBar(
                      'Fat',
                      model.fatCurrent.toInt(),
                      model.fatTarget.toInt(),
                      const Color(0xFFFFC107)),
                ]),
              ),

              const SizedBox(height: 18),

              ...sections
                  .asMap()
                  .entries
                  .map((e) => _buildMealCard(e.key, e.value))
                  .toList(),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _macroBar(
      String label, int current, int goal, Color color) {
    final prog =
    goal == 0 ? 0.0 : (current / goal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('$current / $goal g',
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: prog,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMealCard(int idx, _MealSection s) {
    final isOpen = _openIndex == idx;
    final items = _mealItems[s.name]!;
    final text = s.target > 0
        ? "${s.consumed} / ${s.target} Cal"
        : "${s.consumed} Cal";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              s.name,
              style:
              const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(text),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _openSearchForMeal(s.name),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 250),
                  turns: isOpen ? 0.5 : 0,
                  child: IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: () {
                      setState(() =>
                      _openIndex = isOpen ? null : idx);
                    },
                  ),
                ),
              ],
            ),
            onTap: () =>
                setState(() => _openIndex = isOpen ? null : idx),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            child: ConstrainedBox(
              constraints:
              isOpen ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: Column(
                  children: [
                    _mealSummary(s.name, items),
                    const SizedBox(height: 10),

                    items.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10),
                      child: Text(
                        "No items added.",
                        style: TextStyle(
                            color: Colors.grey.shade600),
                      ),
                    )
                        : Column(
                      children: items
                          .asMap()
                          .entries
                          .map((e) {
                        final i = e.key;
                        final it = e.value;

                        return Container(
                          margin: const EdgeInsets
                              .symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color:
                                Colors.grey.shade300),
                          ),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets
                                .symmetric(
                                horizontal: 16,
                                vertical: 10),
                            title: Text(it.name),
                            subtitle: Text(it.serving),
                            trailing: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                Text(
                                  "${it.kcal} Cal",
                                  style: const TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .w700),
                                ),

                                if (_isEditableDate())
                                  PopupMenuButton<String>(
                                    onSelected: (v) {
                                      if (v == "edit") {
                                        _onEditItem(
                                            s.name, i);
                                      }
                                      if (v == "delete") {
                                        _onDeleteItem(
                                            s.name, i);
                                      }
                                    },
                                    itemBuilder: (_) =>
                                    const [
                                      PopupMenuItem(
                                          value:
                                          "edit",
                                          child: Text(
                                              "Edit")),
                                      PopupMenuItem(
                                          value:
                                          "delete",
                                          child: Text(
                                            "Delete",
                                            style: TextStyle(
                                                color:
                                                Colors.red),
                                          )),
                                    ],
                                  ),

                                if (!_isEditableDate())
                                  const SizedBox.shrink(),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Text(
                            'To add items, go to Nutrition → Add Meal',
                            style:
                            TextStyle(color: Colors.black54),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                  const SearchMealScreen()),
                            );
                          },
                          child: const Text('Search'),
                        )
                      ]),
                    ),

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
    final totalKcal =
    items.fold<int>(0, (p, e) => p + e.kcal);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
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
          Text(
            "$totalKcal kcal",
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _topCalorieCard(
      int consumed, int total, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        SizedBox(
          height: 80,
          width: 80,
          child: CustomPaint(
            painter: _RingPainter(
              progress: progress,
              strokeWidth: 8,
              colors: const [
                Color(0xFFFFA726),
                Color(0xFFFF8A00)
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$consumed of $total Cal",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Text("Keep going — every meal matters"),
            ]),
      ]),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center =
    Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width / 2) - strokeWidth / 2;

    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade300;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final rect =
    Rect.fromCircle(center: center, radius: radius);

    final fgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi /
            2 +
            (2 * pi * progress),
        colors: colors,
      ).createShader(rect);

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress;
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
    final center =
    Offset(size.width / 2, size.height / 2);
    final radius =
        (min(size.width, size.height) - ringWidth) /
            2;

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

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      prog,
    );
  }

  @override
  bool shouldRepaint(
      covariant _SolidRingPainterMock
      oldDelegate) =>
      oldDelegate.progress != progress;
}
