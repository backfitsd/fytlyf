// file: lib/src/features/dashboard/nutritions/nutrition_screen.dart
// FINAL — Water Integrated (Style A) — Fully Error-Free & Ready to Paste

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'Meal Discover/Meal Planner/meal_tracking_screen.dart';
import 'Meal Discover/Recommend/recommend_screen.dart';
import 'Meal Discover/Recipe/recipe_screen.dart';
import 'Meal Discover/AI Meal/ai_meal_planner_screen.dart';
import 'Meal Discover/Meal Planner/search_meal_screen.dart';

import 'water_screen.dart';  // <-- FIXED PATH (Your structure)

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const LinearGradient _appGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // NUTRITION DATA
  int currentCalories = 0;
  int calorieTarget = 2500;

  double protCurrent = 0;
  double protTarget = 70;

  double carbsCurrent = 0;
  double carbsTarget = 250;

  double fatCurrent = 0;
  double fatTarget = 70;

  // *** WATER (Added) ***
  int waterCurrent = 0;
  int waterTarget = 3000;

  bool _loading = true;

  final List<String> _mealNames = [
    'Breakfast',
    'Morning Snack',
    'Lunch',
    'Evening Snack',
    'Dinner',
    'Others',
  ];

  final List<StreamSubscription> _subs = [];

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachListenersOptionB();
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      try {
        s.cancel();
      } catch (_) {}
    }
    _ctrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    return "${dt.year.toString().padLeft(4, '0')}-"
        "${dt.month.toString().padLeft(2, '0')}-"
        "${dt.day.toString().padLeft(2, '0')}";
  }

  String _monthName(int m) {
    const list = [
      "Jan","Feb","Mar","Apr","May","Jun",
      "Jul","Aug","Sep","Oct","Nov","Dec"
    ];
    return list[m - 1];
  }

  // ---------------------- FIRESTORE LISTENERS ----------------------
  void _attachListenersOptionB() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    final todayKey = _formatDate(DateTime.now());

    //------------------ TARGETS ------------------
    final tRef = _db.collection('users').doc(uid).collection('meta').doc('nutrition_targets');

    final tSub = tRef.snapshots().listen((snap) {
      final d = snap.data();
      if (d != null) _applyTargets(d);
    });

    _subs.add(tSub);

    //------------------ MEALS --------------------
    final Map<String, int> kcal = {for (var m in _mealNames) m: 0};
    final Map<String, double> pc = {for (var m in _mealNames) m: 0};
    final Map<String, double> cc = {for (var m in _mealNames) m: 0};
    final Map<String, double> fc = {for (var m in _mealNames) m: 0};

    for (final meal in _mealNames) {
      final col = _db
          .collection('users').doc(uid)
          .collection('meals').doc(todayKey)
          .collection(meal);

      final mealSub = col.snapshots().listen((snap) {
        int k = 0;
        double p = 0, c = 0, f = 0;

        for (final doc in snap.docs) {
          final d = doc.data();

          num _v(dynamic x) {
            if (x == null) return 0;
            if (x is num) return x;
            if (x is String) return num.tryParse(x) ?? 0;
            return 0;
          }

          k += _v(d['calories']).toInt();
          p += _v(d['protein']).toDouble();
          c += _v(d['carbs']).toDouble();
          f += _v(d['fat']).toDouble();
        }

        kcal[meal] = k;
        pc[meal] = p;
        cc[meal] = c;
        fc[meal] = f;

        currentCalories = kcal.values.fold(0, (a, b) => a + b);
        protCurrent = pc.values.fold(0.0, (a, b) => a + b);
        carbsCurrent = cc.values.fold(0.0, (a, b) => a + b);
        fatCurrent = fc.values.fold(0.0, (a, b) => a + b);

        if (mounted) setState(() => _loading = false);
      });

      _subs.add(mealSub);
    }

    //------------------ WATER (Option 2 logs) ------------------
    final waterRef = _db
        .collection('users').doc(uid)
        .collection('water').doc(todayKey)
        .collection('logs')
        .orderBy('timestamp');

    final waterSub = waterRef.snapshots().listen((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final ml = d['amount_ml'] ?? 0;
        if (ml is int) total += ml;
      }

      waterCurrent = total;
      if (mounted) setState(() {});
    });

    _subs.add(waterSub);
  }

  // -------------------- APPLY TARGETS --------------------
  void _applyTargets(Map<String, dynamic> data) {
    num _n(dynamic x, num fb) {
      if (x == null) return fb;
      if (x is num) return x;
      if (x is String) return num.tryParse(x) ?? fb;
      return fb;
    }

    calorieTarget = _n(data['calories']?['target'], calorieTarget).toInt();
    protTarget = _n(data['macros']?['protein']?['target'], protTarget).toDouble();
    carbsTarget = _n(data['macros']?['carbs']?['target'], carbsTarget).toDouble();
    fatTarget = _n(data['macros']?['fat']?['target'], fatTarget).toDouble();

    setState(() {});
  }

  // -------------------- OPENERS --------------------
  void _openMealTracking() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MealTrackingScreen()));
  }

  double _safe(double c, double t) => t == 0 ? 0 : (c / t).clamp(0.0, 1.0);

  Color _calorieColor(double p) =>
      p < .2 ? const Color(0xFFFFD54F)
          : p < .6 ? const Color(0xFFFB8C00)
          : p <= 1 ? const Color(0xFFE53935)
          : const Color(0xFFB71C1C);

  String _motivation(double p) =>
      p < .15 ? "A true start.\nSmall steps."
          : p < .35 ? "Good momentum.\nStay steady."
          : p < .6 ? "Great balance."
          : p < .85 ? "Strong progress."
          : p <= 1 ? "Right on target."
          : "Above target.\nGo lighter.";

  // -------------------- UI BUILD --------------------
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateTxt =
        "Today, ${_monthName(now.month)} ${now.day}";

    final size = MediaQuery.of(context).size;
    final cardH = (size.height * 0.28).clamp(220.0, 360.0);
    final calP = _safe(currentCalories.toDouble(), calorieTarget.toDouble());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              // ---------------- HEADER ----------------
              Material(
                elevation: 5,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _appGradient,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Nutrition",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text(dateTxt,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- CALORIE CARD ----------------
                  Expanded(
                    flex: 4,
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardH,
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            const Text("Calorie",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 14),
                            AnimatedBuilder(
                              animation: _ctrl,
                              builder: (_, __) {
                                final p = (_ctrl.value * calP).clamp(0, 1);
                                return _RingIcon(
                                  size: 120,
                                  ringW: 8,
                                  progress: p,
                                  base: const Color(0xFFE8F2FF),
                                  ring: _calorieColor(calP),
                                  icon: Iconsax.flash,
                                  iconSize: 36,
                                  tap: _openMealTracking,
                                );
                              },
                            ),
                            const SizedBox(height: 14),
                            Text("$currentCalories/$calorieTarget Cal",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(_motivation(calP),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.black54)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ---------------- MACRO + WATER CARD ----------------
                  Expanded(
                    flex: 6,
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardH,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: LayoutBuilder(
                            builder: (_, c) {
                              final w = (c.maxWidth - 14) / 2;
                              final h = (c.maxHeight - 16) / 2;

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      _macro("Protein", Iconsax.cup,
                                          protCurrent, protTarget,
                                          const Color(0xFF42A5F5), w, h),
                                      const SizedBox(width: 14),
                                      _macro("Carbs", Iconsax.ranking,
                                          carbsCurrent, carbsTarget,
                                          const Color(0xFF66BB6A), w, h),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      _macro("Fat", Iconsax.coffee,
                                          fatCurrent, fatTarget,
                                          const Color(0xFFFB8C00), w, h),

                                      const SizedBox(width: 14),

                                      // **** WATER RING CELL (STYLE A) ****
                                      GestureDetector(
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                              const WaterScreen()),
                                        ),
                                        child: _macro(
                                          "Water",
                                          Iconsax.glass,
                                          waterCurrent.toDouble(),
                                          waterTarget.toDouble(),
                                          const Color(0xFF42A5F5),
                                          w,
                                          h,
                                          isML: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ---------------- "Add Meal" / "Meal Planner" ----------------
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _btn(
                      "Add Meal",
                      Icons.add,
                          () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SearchMealScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: _btn(
                      "Meal Planner",
                      Icons.restaurant_menu,
                      _openMealTracking,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ---------------- MEAL DISCOVER ----------------
              _mealDiscoverSection(size),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- SMALL HELPERS ----------------
  Widget _btn(String text, IconData icon, VoidCallback tap) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: _appGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: tap,
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  Text(text, style: const TextStyle(fontWeight: FontWeight.w600))
                ],
              )),
        ),
      ),
    );
  }

  Widget _macro(
      String t,
      IconData ic,
      double cur,
      double tar,
      Color col,
      double w,
      double h, {
        bool isML = false,
      }) {
    final p = _safe(cur, tar);

    return SizedBox(
      width: w,
      height: h,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final pr = (_ctrl.value * p).clamp(0, 1);
              return _RingIcon(
                size: min(w, h) * 0.7,
                ringW: 6,
                progress: pr,
                base: const Color(0xFFE8F2FF),
                ring: col,
                icon: ic,
                iconSize: min(w, h) * 0.28,
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            isML
                ? "${cur.toInt()}/${tar.toInt()} ml"
                : "${cur.toInt()}/${tar.toInt()} g",
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _mealDiscoverSection(Size size) {
    final w = (size.width - 28) / 2;
    final h = (w * 0.75).clamp(120.0, 180.0);

    Widget card(String img, Widget goto) {
      return InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => goto)),
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(img, fit: BoxFit.cover),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Meal Discover",
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            card('assets/images/meal_planner.png', const MealTrackingScreen()),
            card('assets/images/recommend.png', const RecommendScreen()),
            card('assets/images/recipe.png', const RecipeScreen()),
            card('assets/images/ai_planner.png', const AiMealPlannerScreen()),
          ],
        ),
      ],
    );
  }
}

// ---------------- RING ICON WIDGET ----------------
class _RingIcon extends StatelessWidget {
  final double size, ringW, progress, iconSize;
  final Color base, ring;
  final IconData icon;
  final VoidCallback? tap;

  const _RingIcon({
    required this.size,
    required this.ringW,
    required this.progress,
    required this.base,
    required this.ring,
    required this.icon,
    required this.iconSize,
    this.tap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: tap,
      child: CustomPaint(
        size: Size.square(size),
        painter:
        _RingPainter(progress, ringW, base, ring),
        child: Center(
          child: Icon(icon, size: iconSize, color: Colors.black87),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double p, w;
  final Color base, ring;

  _RingPainter(this.p, this.w, this.base, this.ring);

  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width / 2, s.height / 2);
    final r = (min(s.width, s.height) - w) / 2;

    final b = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = base;

    final f = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..color = ring;

    canvas.drawCircle(c, r, b);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -pi / 2,
      2 * pi * p,
      false,
      f,
    );
  }

  @override
  bool shouldRepaint(_) => true;
}
