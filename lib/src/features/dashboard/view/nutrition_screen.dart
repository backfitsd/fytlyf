// file: lib/src/features/dashboard/view/nutrition_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';

// Import the new meal tracking screen (same folder)
import 'meal_tracking_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // App gradient (re-used)
  static const LinearGradient _appGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Hydration state (copied behavior from Dashboard)
  double currentWater = 1.2; // example starting liters
  final double goalWater = 2.5;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // start animation on mount
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ---------- Water popup (same as before) ----------
  void _showWaterPopup(BuildContext context) {
    double tempWater = currentWater;
    int selectedAmount = 250;
    const int maxAmount = 500;
    const int step = 10;

    final scrollController =
    FixedExtentScrollController(initialItem: selectedAmount ~/ step);

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        final wheelItemExtent = height * 0.03;
        final wheelVisibleHeight = wheelItemExtent * 3;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            double progress = (tempWater / goalWater).clamp(0.0, 1.0);

            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: width * 0.08),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hydration",
                          style: TextStyle(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Today, Nov 10",
                          style: TextStyle(
                            fontSize: width * 0.035,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    Row(
                      children: [
                        /// LEFT SIDE – CIRCLE PROGRESS
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: width * 0.35,
                                    width: width * 0.35,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 9,
                                      backgroundColor:
                                      Colors.blueAccent.withOpacity(0.15),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.water_drop_rounded,
                                    size: width * 0.06,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.015),
                              Text(
                                "${tempWater.toStringAsFixed(1)}L / ${goalWater.toStringAsFixed(1)}L",
                                style: TextStyle(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// RIGHT SIDE – WHEEL + BUTTONS
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Text(
                                "Select water (ml)",
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              SizedBox(height: height * 0.01),

                              /// Wheel (3 visible items)
                              SizedBox(
                                height: wheelVisibleHeight,
                                child: ListWheelScrollView.useDelegate(
                                  controller: scrollController,
                                  itemExtent: wheelItemExtent,
                                  physics: const FixedExtentScrollPhysics(),
                                  overAndUnderCenterOpacity: 0.5,
                                  onSelectedItemChanged: (index) {
                                    dialogSetState(() {
                                      selectedAmount = index * step;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: (maxAmount ~/ step) + 1,
                                    builder: (context, index) {
                                      int value = index * step;
                                      bool isSelected = value == selectedAmount;

                                      return AnimatedDefaultTextStyle(
                                        duration:
                                        const Duration(milliseconds: 150),
                                        style: TextStyle(
                                          fontSize: isSelected
                                              ? width * 0.045
                                              : width * 0.038,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.blueAccent
                                              : Colors.black38,
                                        ),
                                        child: Text("$value ml"),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(height: height * 0.015),

                              /// - and + buttons (Option B)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      dialogSetState(() {
                                        tempWater -= selectedAmount / 1000;
                                        if (tempWater < 0) tempWater = 0;
                                        setState(() {
                                          currentWater = double.parse(
                                              tempWater.toStringAsFixed(1));
                                        });
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.06),
                                  InkWell(
                                    onTap: () {
                                      dialogSetState(() {
                                        tempWater += selectedAmount / 1000;
                                        if (tempWater > goalWater) {
                                          tempWater = goalWater;
                                        }
                                        setState(() {
                                          currentWater = double.parse(
                                              tempWater.toStringAsFixed(1));
                                        });
                                      });
                                    },
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    _exploreButton(
                      context,
                      onTap: () {
                        setState(() {
                          currentWater = tempWater;
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _metric(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(
              value: 0.7,
              strokeWidth: 4,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Icon(icon, size: 18, color: color),
        ]),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54)),
      ]),
    );
  }

  // ✅ Updated gradient explore button (same for both popups)
  Widget _exploreButton(BuildContext context, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF3D00),
                Color(0xFFFF6D00),
                Color(0xFFFFA726),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "EXPLORE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- UI build (rings animate using _ctrl) ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;

    // Adaptive card height
    final double cardHeight = (isPortrait
        ? size.height.clamp(560.0, 1000.0) * 0.25 * 1.2
        : size.height.clamp(360.0, 800.0) * 0.35 * 1.2)
        .toDouble();

    // Example progress (replace with your data)
    const int current = 1250;
    const int goal = 2500;
    final double progressRaw = current / goal;

    // Dynamic motivational line based on progress
    String _motivation(double p) {
      if (p <= 0.15) return "A true start is a gentle one.\nSmall steps build strong habits.";
      if (p <= 0.35) return "Good momentum.\nKeep choices steady and simple.";
      if (p <= 0.6) return "Great balance.\nFuel up and stay consistent.";
      if (p <= 0.85) return "Strong progress.\nAlign the next meal to your goal.";
      if (p <= 1.0) return "Right on target.\nTiny tweaks make perfect days.";
      return "You’re above target.\nGo lighter now and hydrate well.";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              // ---------- Header (now with app gradient) ----------
              Material(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: _appGradient,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Nutrition',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Today, Nov 10',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ---------- Main Row ----------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== First Card: Calorie Progress =====
                  Expanded(
                    flex: 4,
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final cw = constraints.maxWidth;
                              final ch = constraints.maxHeight;

                              // Progress ring sizing
                              double ringSize = (min(cw, ch) * 0.65 * 1.2 * 1.2)
                                  .clamp(90.0, min(cw * 0.98, ch * 0.98));
                              final double ringWidth = (ringSize * 0.07).clamp(3.0, 7.0).toDouble();

                              final double iconSize = ((ringSize / 1.5) * 0.42).toDouble();
                              final double vGapSmall = (ch * 0.02).clamp(6.0, 14.0).toDouble();
                              final Color calorieColor = _calorieSolidColor(progressRaw);

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  // Top gap
                                  SizedBox(height: vGapSmall * 0.5),

                                  // Title
                                  const Text(
                                    'Calorie',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),

                                  SizedBox(height: vGapSmall * 1.4 * 1.1),

                                  // Animated ring (use AnimatedBuilder)
                                  Center(
                                    child: AnimatedBuilder(
                                      animation: _ctrl,
                                      builder: (context, _) {
                                        final animatedProgress = (_ctrl.value * progressRaw).clamp(0.0, 1.0);
                                        return _SolidRingWithIcon(
                                          size: ringSize,
                                          ringWidth: ringWidth,
                                          progress: animatedProgress,
                                          baseColor: const Color(0xFFE8F2FF),
                                          ringColor: calorieColor,
                                          icon: Iconsax.flash,
                                          iconSize: iconSize,
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: vGapSmall * 1.3 * 1.2),

                                  // Progress text
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${(progressRaw * goal).round()}/${goal} g',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  const Spacer(),

                                  // Motivational line at the BOTTOM of the 1st card
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                                    child: Text(
                                      _motivation(progressRaw),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      maxLines: 3,
                                      overflow: TextOverflow.visible,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // ===== Second Card: Nutrients =====
                  Expanded(
                    flex: 6,
                    child: Card(
                      elevation: 6,
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      child: SizedBox(
                        height: cardHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double cw = constraints.maxWidth;
                              final double ch = constraints.maxHeight;
                              const double hGap = 14, vGap = 16;
                              final double colWidth = ((cw - hGap) / 2);
                              final double rowHeight = ((ch - vGap) / 2);

                              final double ringSize = (min(colWidth, rowHeight) * 0.7).clamp(44.0, 120.0).toDouble();
                              final double ringWidth = (ringSize * 0.07).clamp(3.0, 6.0).toDouble();
                              final double titleSize = (ringSize * 0.26).clamp(12.0, 17.0).toDouble();
                              final double valueSize =
                              (ringSize * 0.23 * 0.8 * 1.1).clamp(9.0, 15.0).toDouble();

                              Widget buildCell(String title, IconData icon, double targetProgress, String value, Color color) {
                                final bool isWaterCell = title.toLowerCase() == 'water';
                                final String displayValue = isWaterCell
                                    ? '${currentWater.toStringAsFixed(1)}/${goalWater.toStringAsFixed(1)}L'
                                    : value;
                                final double progressForCell = targetProgress;

                                Widget content = SizedBox(
                                  width: colWidth,
                                  height: rowHeight,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontSize: titleSize,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      AnimatedBuilder(
                                        animation: _ctrl,
                                        builder: (context, _) {
                                          final animatedProgress = (_ctrl.value * progressForCell).clamp(0.0, 1.0);
                                          return _SolidRingWithIcon(
                                            size: ringSize,
                                            ringWidth: ringWidth,
                                            progress: animatedProgress,
                                            baseColor: const Color(0xFFE8F2FF),
                                            ringColor: color,
                                            icon: icon,
                                            iconSize: (ringSize * 0.42).clamp(16.0, ringSize * 0.55).toDouble(),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          displayValue,
                                          style: TextStyle(fontSize: valueSize, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                // Make the water cell tappable to open popup
                                if (isWaterCell) {
                                  return GestureDetector(
                                    onTap: () => _showWaterPopup(context),
                                    child: content,
                                  );
                                } else {
                                  return content;
                                }
                              }

                              return Column(children: [
                                Row(
                                  children: [
                                    buildCell('Protein', Iconsax.cup, 0.55, '65/120g', const Color(0xFF42A5F5)),
                                    const SizedBox(width: hGap),
                                    buildCell('Carbs', Iconsax.ranking, 0.72, '180/250g', const Color(0xFF66BB6A)),
                                  ],
                                ),
                                const SizedBox(height: vGap),
                                Row(
                                  children: [
                                    buildCell('Fat', Iconsax.coffee, 0.48, '45/70g', const Color(0xFFFB8C00)),
                                    const SizedBox(width: hGap),
                                    // For Water, pass dynamic target progress based on currentWater/goalWater
                                    buildCell('Water', Iconsax.glass, (currentWater / goalWater).clamp(0.0, 1.0), '1.2/2.5L', const Color(0xFF64B5FF)),
                                  ],
                                ),
                              ]);
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ---------- Buttons ROW (outside the cards) ----------
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Align left button under the calorie card (flex 4)
                  Expanded(
                    flex: 4,
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: min(160, size.width * 0.34),
                        height: 48,
                        child: GradientBorderButton(
                          gradient: _appGradient,
                          onPressed: () {
                            // TODO: implement add meal
                          },
                          icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                          label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Align right button under the nutrients card (flex 5)
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: min(320, size.width * 0.48),
                        height: 48,
                        child: GradientBorderButton(
                          gradient: _appGradient,
                          onPressed: () => _showWaterPopup(context), // <-- wired to popup
                          icon: const Icon(Icons.local_drink, size: 18, color: Colors.blue),
                          label: const Text('Add Water Intake', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ---------- NEW: Meal Tracking (empty boxes only) ----------
              LayoutBuilder(builder: (context, layoutConstraints) {
                final double availableWidth = layoutConstraints.maxWidth;
                const double hSpacing = 12.0;
                final double cardWidth = (availableWidth - hSpacing) / 2;
                // proportional height — tweak multiplier if you want taller/shorter boxes
                final double cardHeight = (cardWidth * 0.45).clamp(100.0, 150.0);

                Widget emptyCard() {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.transparent),
                    ),
                  );
                }

                // First card will act as Meal Planner trigger — show a plus label/icon
                Widget mealPlannerCard() {
                  return GestureDetector(
                    onTap: () {
                      // Navigate to the dedicated Meal Tracking screen you requested
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealTrackingScreen()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.restaurant_menu_outlined, size: 28, color: Colors.black54),
                          const SizedBox(height: 8),
                          const Text('Meal Planner', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          const Text('Tap to open meal tracking', style: TextStyle(fontSize: 12, color: Colors.black45)),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Meal Tracking',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    Wrap(
                      spacing: hSpacing,
                      runSpacing: 12,
                      children: [
                        // top-left tappable meal planner
                        SizedBox(width: cardWidth, height: cardHeight, child: mealPlannerCard()),
                        SizedBox(width: cardWidth, height: cardHeight, child: emptyCard()),
                        SizedBox(width: cardWidth, height: cardHeight, child: emptyCard()),
                        SizedBox(width: cardWidth, height: cardHeight, child: emptyCard()),
                      ],
                    ),

                    const SizedBox(height: 18),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gradient bordered button — white inner fill with gradient stroke.
class GradientBorderButton extends StatelessWidget {
  final LinearGradient gradient;
  final Widget label;
  final Widget icon;
  final VoidCallback? onPressed;
  final double borderWidth;
  final double borderRadius;

  const GradientBorderButton({
    Key? key,
    required this.gradient,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.borderWidth = 2.0,
    this.borderRadius = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Outer gradient stroke container; inner is white button surface
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        padding: EdgeInsets.all(borderWidth),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(borderRadius - borderWidth),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1)),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  const SizedBox(width: 8),
                  DefaultTextStyle.merge(
                    style: const TextStyle(color: Colors.black87),
                    child: label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color _calorieSolidColor(double p) {
  if (p <= 0.2) return const Color(0xFFFFD54F); // yellow
  if (p <= 0.6) return const Color(0xFFFB8C00); // orange
  if (p <= 1.0) return const Color(0xFFE53935); // red
  return const Color(0xFFB71C1C); // deep red (overflow)
}

/// ----- Solid ring with center icon -----
class _SolidRingWithIcon extends StatelessWidget {
  final double size, ringWidth, progress, iconSize;
  final Color baseColor, ringColor;
  final IconData icon;

  const _SolidRingWithIcon({
    required this.size,
    required this.ringWidth,
    required this.progress, // 0..1 (animated)
    required this.baseColor,
    required this.ringColor,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _SolidRingPainter(
              progress: progress,
              ringWidth: ringWidth,
              ringColor: ringColor,
              baseColor: baseColor,
            ),
          ),
          Icon(icon, size: iconSize, color: Colors.black87),
        ],
      ),
    );
  }
}

class _SolidRingPainter extends CustomPainter {
  final double progress; // 0..1
  final double ringWidth;
  final Color ringColor;
  final Color baseColor;

  _SolidRingPainter({
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
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2, 2 * pi * progress, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _SolidRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringWidth != ringWidth ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.baseColor != baseColor;
  }
}

/// -------------------- Meal card widget --------------------
class _MealCard extends StatelessWidget {
  final String title;
  final int kcal;
  final Color progressColor;
  final String protein;
  final String carbs;
  final String fat;
  final String time;
  final IconData leadingIcon;
  final bool showAddCircle;
  final VoidCallback? onTap;

  const _MealCard({
    Key? key,
    required this.title,
    required this.kcal,
    required this.progressColor,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.time,
    required this.leadingIcon,
    this.showAddCircle = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Visual style similar to the provided image (compact, rounded)
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // image / icon circle
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade100,
              child: Icon(leadingIcon, size: 26, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            // details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text('$kcal kcal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 6),
                  // small progress indicator bar
                  LayoutBuilder(builder: (context, constraints) {
                    final double barWidth = constraints.maxWidth;
                    final double used = (kcal / 800).clamp(0.06, 1.0); // arbitrary visual ratio
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: barWidth,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: used,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: progressColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(child: Text('$protein $carbs $fat', style: const TextStyle(fontSize: 11, color: Colors.black54))),
                            Text(time, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            if (showAddCircle)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.add, size: 18, color: Colors.blueAccent),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
