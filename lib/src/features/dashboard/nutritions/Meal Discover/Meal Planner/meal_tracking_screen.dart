// file: lib/src/features/dashboard/nutritions/meal_tracking_screen.dart
// Meal Tracking screen with embedded Meal Adder UI per-card (Option A styling).
// - Merged MealAdder UI into each expandable meal card.
// - Only one card open at a time.
// - Separate item lists per meal (Breakfast/Lunch/Dinner).
// - Logic for add/edit/delete preserved (dialogs & bottom sheet).
// - Animated ring & painters kept as before.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// ----------------------
/// Nutrition Model
/// ----------------------
class NutritionModel extends ChangeNotifier {
  NutritionModel._internal();
  static final NutritionModel instance = NutritionModel._internal();

  int totalKcal = 2500;
  int consumedKcal = 1250;

  double fatCurrent = 65;
  double fatTarget = 120;

  double carbsCurrent = 180;
  double carbsTarget = 250;

  double protCurrent = 45;
  double protTarget = 70;

  double waterCurrent = 1.2;
  double waterTarget = 2.5;

  void updateKcal({required int consumed, required int total}) {
    consumedKcal = consumed;
    totalKcal = total;
    notifyListeners();
  }

  void updateFat({required double current, required double target}) {
    fatCurrent = current;
    fatTarget = target;
    notifyListeners();
  }

  void updateCarbs({required double current, required double target}) {
    carbsCurrent = current;
    carbsTarget = target;
    notifyListeners();
  }

  void updateProt({required double current, required double target}) {
    protCurrent = current;
    protTarget = target;
    notifyListeners();
  }

  void updateWater({required double current, required double target}) {
    waterCurrent = current;
    waterTarget = target;
    notifyListeners();
  }
}

/// ----------------------
/// Food item (used per meal)
/// ----------------------
class _FoodItem {
  String name;
  String qtyLabel; // e.g. "250 g" or "250 ml"
  int kcal;
  _FoodItem({required this.name, required this.qtyLabel, required this.kcal});
}

/// ----------------------
/// Meal Tracking Screen
/// ----------------------
class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> {
  // Accent color (Option A orange)
  static const Color _accent = Color(0xFFFFA726);
  static const Color _scaffoldBg = Color(0xFFF4F7FB);

  // Sections (display order)
  final List<_MealSection> sections = [
    _MealSection(name: 'Breakfast', consumed: 283, target: 675),
    _MealSection(name: 'Morning Snack', consumed: 0, target: 330),
    _MealSection(name: 'Lunch', consumed: 175, target: 375),
    _MealSection(name: 'Evening Snack', consumed: 557, target: 100),
    _MealSection(name: 'Dinner', consumed: 0, target: 400),
    _MealSection(name: 'Others', consumed: 0, target: 0),
  ];

  // Per-meal items (start with some for Breakfast & Lunch)
  final Map<String, List<_FoodItem>> _mealItems = {
    'Breakfast': [
      _FoodItem(name: 'Rice', qtyLabel: '250 g', kcal: 200),
      _FoodItem(name: 'Milk', qtyLabel: '250 ml', kcal: 150),
    ],
    'Morning Snack': [],
    'Lunch': [
      _FoodItem(name: 'Salad', qtyLabel: '150 g', kcal: 120),
    ],
    'Evening Snack': [],
    'Dinner': [],
    'Others': [],
  };

  // which section index is expanded; only one open at a time (Option 1)
  int? _openIndex;

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[m - 1];
  }

  // Open (expand) a section by index
  void _toggleSection(int index) {
    setState(() {
      if (_openIndex == index) {
        _openIndex = null;
      } else {
        _openIndex = index;
      }
    });
  }

  // show add/edit dialog for a specific meal and optionally edit a specific item
  void _showAddEditDialog({required String mealName, int? editIndex}) {
    final items = _mealItems[mealName]!;
    final isEdit = editIndex != null;
    final nameCtrl = TextEditingController(text: isEdit ? items[editIndex!].name : '');
    final qtyCtrl = TextEditingController(text: isEdit ? items[editIndex!].qtyLabel : '');
    final kcalCtrl = TextEditingController(text: isEdit ? items[editIndex!].kcal.toString() : '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(isEdit ? 'Edit item' : 'Add item to $mealName', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Food item'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity (e.g. 250 g, 1 cup)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: kcalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final qty = qtyCtrl.text.trim();
                final kcal = int.tryParse(kcalCtrl.text.trim()) ?? 0;
                if (name.isEmpty || qty.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill name and qty')));
                  return;
                }
                setState(() {
                  if (isEdit) {
                    items[editIndex!] = _FoodItem(name: name, qtyLabel: qty, kcal: kcal);
                  } else {
                    items.insert(0, _FoodItem(name: name, qtyLabel: qty, kcal: kcal));
                  }
                });
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        );
      },
    );
  }

  // item options in bottom sheet (edit/delete)
  void _showItemMenu({required String mealName, required int index}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditDialog(mealName: mealName, editIndex: index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _mealItems[mealName]!.removeAt(index);
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Close'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  // Build the embedded Meal Adder UI (summary + search-like row + list + action row)
  Widget _buildEmbeddedMealAdder(String mealName, int sectionIndex) {
    final items = _mealItems[mealName]!;
    final totalKcal = items.fold<int>(0, (p, e) => p + e.kcal);
    // keep some mocked macro values for the summary (these can be wired to NutritionModel if desired)
    final prot = 10;
    final carbs = 70;
    final fat = 10;

    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0,4))],
      ),
      child: Column(
        children: [
          // summary card (ring + macros)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                width: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(72,72),
                      painter: _SolidRingPainterMock(
                        progress: min(1.0, totalKcal / 800),
                        ringWidth: 8,
                        ringColor: _accent,
                        baseColor: const Color(0xFFF8F2EE),
                      ),
                    ),
                    Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0,3))],
                      ),
                      child: const Icon(Icons.restaurant, size: 18, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(mealName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('${items.length} items', style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        Text('$totalKcal kcal', style: const TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _macroRow(Iconsax.cup, 'Protein', prot, 30),
                    const SizedBox(height: 8),
                    _macroRow(Iconsax.ranking, 'Carbs', carbs, 100),
                    const SizedBox(height: 8),
                    _macroRow(Iconsax.coffee, 'Fat', fat, 30),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // search-like row / quick-add bar
          InkWell(
            onTap: () => _showAddEditDialog(mealName: mealName),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0,3))],
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: Colors.black54),
                  const SizedBox(width: 10),
                  Expanded(child: Text('+ Meal', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600))),
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Quick', style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w700)),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // items list
          items.isEmpty
              ? Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text('No items yet. Tap + or the bar above to add to $mealName.', style: TextStyle(color: Colors.black54), textAlign: TextAlign.center),
          )
              : Column(
            children: items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  subtitle: Text(item.qtyLabel, style: const TextStyle(color: Colors.black54)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('${item.kcal} Cal', style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(width: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showItemMenu(mealName: mealName, index: idx),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        child: Icon(Icons.more_vert, size: 20, color: Colors.black54),
                      ),
                    ),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // action row (Add item + Done)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _showAddEditDialog(mealName: mealName),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add, color: Colors.black87),
                      SizedBox(width: 8),
                      Text('Add item', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // close the section (user done)
                  setState(() {
                    _openIndex = null;
                  });
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                  backgroundColor: _accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // macro row for embedded summary
  Widget _macroRow(IconData icon, String label, int current, int goal) {
    final progress = (goal <= 0) ? 0.0 : (current / goal).clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 28,
          width: 28,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.black87),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
                  Text('$current/$goal g', style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(_accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// ---------------------- UI - Main build ----------------------
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = "Today, ${_monthName(now.month)} ${now.day}";

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedBuilder(
            animation: NutritionModel.instance,
            builder: (context, _) {
              final model = NutritionModel.instance;
              final totalKcal = model.totalKcal;
              final consumedKcal = model.consumedKcal;
              final kcalProgress = totalKcal == 0 ? 0.0 : consumedKcal / totalKcal;
              final fatPct = model.fatTarget == 0 ? 0.0 : model.fatCurrent / model.fatTarget;
              final carbsPct = model.carbsTarget == 0 ? 0.0 : model.carbsCurrent / model.carbsTarget;
              final protPct = model.protTarget == 0 ? 0.0 : model.protCurrent / model.protTarget;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Text('Track Meal', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0,2))],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text(dateLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Calorie card
                  _buildCalorieCard(kcalProgress, consumedKcal, totalKcal),

                  const SizedBox(height: 20),

                  // Macro card (no water)
                  _buildMacrosCard(protPct, carbsPct, fatPct, model),

                  const SizedBox(height: 24),

                  // Meal rows (each card can expand)
                  ...sections.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final s = entry.value;
                    final isOpen = _openIndex == idx;
                    final text = s.target > 0 ? "${s.consumed} / ${s.target} Cal" : "${s.consumed} Cal";
                    final items = _mealItems[s.name] ?? [];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: _cardDecoration(),
                      child: Column(
                        children: [
                          // The top tile (tappable to open)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            title: Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            subtitle: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              // small add icon
                              GestureDetector(
                                onTap: () {
                                  // open the section first, then show add dialog
                                  setState(() {
                                    _openIndex = idx;
                                  });
                                  // show add after a short frame to ensure expansion UI exists
                                  Future.delayed(Duration(milliseconds: 120), () {
                                    _showAddEditDialog(mealName: s.name);
                                  });
                                },
                                child: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const Icon(Icons.add, size: 18, color: Colors.black87),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // arrow below add (rotates)
                              AnimatedRotation(
                                turns: isOpen ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: GestureDetector(
                                  onTap: () => _toggleSection(idx),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    child: const Icon(Icons.keyboard_arrow_down, size: 22, color: Colors.black54),
                                  ),
                                ),
                              ),
                            ]),
                            onTap: () => _toggleSection(idx), // tap anywhere opens
                          ),

                          // Expanded content (embedded meal adder) when open
                          if (isOpen) _buildEmbeddedMealAdder(s.name, idx),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieCard(double progress, int consumed, int total) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0,4))],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 100,
            width: 100,
            child: AnimatedRing(
              size: 100,
              strokeWidth: 8,
              value: progress,
              gradient: const [
                Color(0xFFFFA726),
                Color(0xFFFF8A00),
                Color(0xFFFF6D00)
              ],
              inner: const Icon(Icons.restaurant, size: 40),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '$consumed of $total Cal',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Keep going — every meal matters!',
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosCard(double p, double c, double f, NutritionModel m) {
    Widget macro(String name, double val, List<Color> g, IconData icon, String unit) {
      return Expanded(
        child: Column(
          children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SizedBox(
              height: 60,
              width: 60,
              child: AnimatedRing(
                size: 60,
                strokeWidth: 6,
                value: val,
                gradient: g,
                inner: Icon(icon, size: 18),
              ),
            ),
            const SizedBox(height: 6),
            Text(unit, style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,3))],
      ),
      child: Row(
        children: [
          macro('Protein', p, const [Color(0xFF42A5F5), Color(0xFF1E88E5)], Iconsax.cup, '${m.protCurrent.toInt()}/${m.protTarget.toInt()}g'),
          macro('Carbs', c, const [Color(0xFF66BB6A), Color(0xFF43A047)], Iconsax.ranking, '${m.carbsCurrent.toInt()}/${m.carbsTarget.toInt()}g'),
          macro('Fat', f, const [Color(0xFFFFC107), Color(0xFFFF9800)], Iconsax.coffee, '${m.fatCurrent.toInt()}/${m.fatTarget.toInt()}g'),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0,4))],
    );
  }
}

/// ----------------------
/// Models & Painters
/// ----------------------
class _MealSection {
  final String name;
  final int consumed;
  final int target;

  _MealSection({required this.name, required this.consumed, required this.target});
}

/// Animated Ring (same as before)
class AnimatedRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final double value;
  final List<Color> gradient;
  final Widget? inner;

  const AnimatedRing({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.value,
    required this.gradient,
    this.inner,
  });

  @override
  State<AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<AnimatedRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic))..addListener(() => setState(() {}));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.0001 || oldWidget.gradient != widget.gradient) {
      _oldValue = oldWidget.value;
      _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
      _controller..reset()..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final val = _anim.value.clamp(0.0, 1.0);
    return SizedBox(
      height: widget.size,
      width: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size(widget.size, widget.size), painter: _RingPainter(progress: val, strokeWidth: widget.strokeWidth, colors: widget.gradient)),
          if (widget.inner != null) widget.inner!,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  _RingPainter({required this.progress, required this.strokeWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final trackPaint = Paint()..style = PaintingStyle.stroke..strokeWidth = strokeWidth..color = Colors.grey.shade300;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(startAngle: -pi / 2, endAngle: -pi / 2 + (2 * pi * progress), colors: colors).createShader(rect);

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.colors != colors;
}

/// Solid ring painter used in embedded summary
class _SolidRingPainterMock extends CustomPainter {
  final double progress;
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;
  _SolidRingPainterMock({required this.progress, required this.ringWidth, required this.ringColor, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width/2, size.height/2);
    final radius = (min(size.width, size.height) - ringWidth) / 2;
    final base = Paint()..style = PaintingStyle.stroke..strokeWidth = ringWidth..strokeCap = StrokeCap.round..color = baseColor;
    canvas.drawCircle(center, radius, base);

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = ringWidth..strokeCap = StrokeCap.round..color = ringColor;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi/2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(covariant _SolidRingPainterMock oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringWidth != ringWidth || oldDelegate.ringColor != ringColor;
  }
}
