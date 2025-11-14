// file: lib/src/features/dashboard/nutritions/meal_tracking_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fytlyf/src/features/dashboard/nutritions/Meal%20Discover/Meal%20Planner/meal_adder_screen.dart' show MealAdderScreen;
import 'package:iconsax/iconsax.dart'; // ADDED: icons used to match nutrition_screen.dart

// ADDED: import MealAdder screen (relative path you specified)
import 'meal_adder_screen.dart';

/// Simple shared nutrition model (singleton)
/// Update values from your Nutrition screen by calling the update... helpers.
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

/// Meal Tracking screen — uses animated gradient rings for calorie + all macros.
class MealTrackingScreen extends StatefulWidget {
  const MealTrackingScreen({Key? key}) : super(key: key);

  @override
  State<MealTrackingScreen> createState() => _MealTrackingScreenState();
}

class _MealTrackingScreenState extends State<MealTrackingScreen> {
  final List<_MealSection> sections = [
    _MealSection(name: 'Breakfast', consumed: 283, target: 675),
    _MealSection(name: 'Morning Snack', consumed: 0, target: 330),
    _MealSection(name: 'Lunch', consumed: 175, target: 375),
    _MealSection(name: 'Evening Snack', consumed: 557, target: 100),
    _MealSection(name: 'Dinner', consumed: 0, target: 400),
    _MealSection(name: 'Others', consumed: 0, target: 0),
  ];

  String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m - 1];
  }

  void _openMealAdder(String mealName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealAdderScreen(mealName: mealName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel = 'Today, ${_monthName(now.month)} ${now.day}';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: AnimatedBuilder(
            animation: NutritionModel.instance,
            builder: (context, _) {
              final model = NutritionModel.instance;
              final totalKcal = model.totalKcal;
              final consumedKcal = model.consumedKcal;
              final kcalProgress =
              (totalKcal == 0) ? 0.0 : (consumedKcal / totalKcal);

              final fatPct =
              (model.fatTarget == 0) ? 0.0 : (model.fatCurrent / model.fatTarget);
              final carbsPct =
              (model.carbsTarget == 0) ? 0.0 : (model.carbsCurrent / model.carbsTarget);
              final protPct =
              (model.protTarget == 0) ? 0.0 : (model.protCurrent / model.protTarget);
              final waterPct =
              (model.waterTarget == 0) ? 0.0 : (model.waterCurrent / model.waterTarget);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER
                  Row(
                    children: [
                      const Text(
                        'Track Meal',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              dateLabel,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // CALORIE CARD — big ring left (center icon updated to Iconsax.flash)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Animated gradient calorie ring (big) — inner icon matches nutrition_screen (Iconsax.flash)
                        SizedBox(
                          height: 90,
                          width: 90,
                          child: AnimatedRing(
                            size: 90,
                            strokeWidth: 9,
                            value: kcalProgress.clamp(0.0, 1.0),
                            gradient: const [
                              Color(0xFFFFA726),
                              Color(0xFFFF8A00),
                              Color(0xFFFF6D00),
                            ],
                            inner: const Icon(Iconsax.flash, size: 36), // match nutrition_screen
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$consumedKcal of $totalKcal Cal',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 8),
                              // horizontal kcal progress painter removed (per your request)
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // MACROS CARD — all rings animated & gradient (icons centered inside each ring)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        // Protein (center icon: Iconsax.cup)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: AnimatedRing(
                                  size: 60,
                                  strokeWidth: 6,
                                  value: protPct.clamp(0.0, 1.0),
                                  gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                                  inner: const Icon(Iconsax.cup, size: 18), // center icon
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Protein', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${model.protCurrent.toInt()}/${model.protTarget.toInt()}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),

                        // Carbs (center icon: Iconsax.ranking)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: AnimatedRing(
                                  size: 60,
                                  strokeWidth: 6,
                                  value: carbsPct.clamp(0.0, 1.0),
                                  gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                                  inner: const Icon(Iconsax.ranking, size: 18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Carbs', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${model.carbsCurrent.toInt()}/${model.carbsTarget.toInt()}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),

                        // Fat (center icon: Iconsax.coffee)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: AnimatedRing(
                                  size: 60,
                                  strokeWidth: 6,
                                  value: fatPct.clamp(0.0, 1.0),
                                  gradient: const [Color(0xFFFFC107), Color(0xFFFF9800)],
                                  inner: const Icon(Iconsax.coffee, size: 18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Fat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${model.fatCurrent.toInt()}/${model.fatTarget.toInt()}g', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),

                        // Water (center icon: Iconsax.glass)
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 60,
                                width: 60,
                                child: AnimatedRing(
                                  size: 60,
                                  strokeWidth: 6,
                                  value: waterPct.clamp(0.0, 1.0),
                                  gradient: const [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                                  inner: const Icon(Iconsax.glass, size: 18),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Water', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text('${model.waterCurrent}/${model.waterTarget}L', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Meal rows (navigation added)
                  ...sections.map((section) {
                    final hasTarget = section.target > 0;
                    final text = hasTarget ? '${section.consumed} of ${section.target} Cal' : '${section.consumed} Cal';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _openMealAdder(section.name), // open meal adder on tapping the whole row
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              Text(section.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 10),
                              // Make the add icon tappable too
                              GestureDetector(
                                onTap: () => _openMealAdder(section.name),
                                child: CircleAvatar(radius: 14, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.add, size: 18)),
                              ),
                            ],
                          ),
                        ),
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
}

/// Small painter for thin rectangular progress bar used under calorie text.
/// (kept in file for compatibility but not used in UI anymore)
class _MiniProgressPainter extends CustomPainter {
  final double progress;
  _MiniProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = Colors.grey.shade200;
    final fg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA726), Color(0xFFFF6D00)],
      ).createShader(Rect.fromLTWH(0, 0, size.width * progress, size.height));

    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6));
    canvas.drawRRect(r, bg);
    if (progress > 0) {
      final r2 = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width * progress, size.height), const Radius.circular(6));
      canvas.drawRRect(r2, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Animated gradient ring widget.
class AnimatedRing extends StatefulWidget {
  final double size;
  final double strokeWidth;
  final double value; // 0..1
  final List<Color> gradient;
  final Widget? inner;

  const AnimatedRing({
    Key? key,
    required this.size,
    required this.strokeWidth,
    required this.value,
    required this.gradient,
    this.inner,
  }) : super(key: key);

  @override
  State<AnimatedRing> createState() => _AnimatedRingState();
}

class _AnimatedRingState extends State<AnimatedRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;
  double _oldValue = 0.0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() => setState(() {}));
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.001 || oldWidget.gradient != widget.gradient) {
      _oldValue = oldWidget.value;
      _controller.duration = const Duration(milliseconds: 700);
      _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller
        ..reset()
        ..forward();
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
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              progress: val,
              strokeWidth: widget.strokeWidth,
              colors: widget.gradient,
            ),
          ),
          if (widget.inner != null) widget.inner!,
        ],
      ),
    );
  }
}

/// Painter that draws the track + animated sweep with a sweep shader (gradient)
class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final List<Color> colors;

  _RingPainter({required this.progress, required this.strokeWidth, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    // background track
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.grey.shade200;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);

    // Sweep gradient from -90deg onward
    final sweepShader = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + 2 * pi * progress,
      tileMode: TileMode.clamp,
      colors: colors,
    ).createShader(rect);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..shader = sweepShader;

    final start = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweepAngle, false, paint);

    // subtle glow
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 2
      ..color = colors.last.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweepAngle, false, glow);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth || oldDelegate.colors != colors;
}

// small model for meal rows
class _MealSection {
  final String name;
  final int consumed;
  final int target;

  _MealSection({required this.name, required this.consumed, required this.target});
}
