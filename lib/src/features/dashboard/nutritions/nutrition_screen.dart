// file: lib/src/features/dashboard/nutritions/nutrition_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter/cupertino.dart';

// import other screens from same folder
import 'Meal Discover/Meal Planner/meal_tracking_screen.dart';
import 'Meal Discover/Recommend/recommend_screen.dart';
import 'Meal Discover/Recipe/recipe_screen.dart';
import 'Meal Discover/AI Meal/ai_meal_planner_screen.dart';
// ADDED: import water screen (relative path from 'nutritions' folder to 'nutrition' folder)
import 'water_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> with SingleTickerProviderStateMixin {
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

  double currentWater = 1.2; // example starting liters
  final double goalWater = 2.5;



  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
                        // Save temporary water, close dialog, then navigate to WaterScreen
                        setState(() {
                          currentWater = tempWater;
                        });
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WaterScreen()),
                        );
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
            gradient: _appGradient,
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

  /// Updated _featureCard — changes annotated with // CHANGED
  Widget _featureCard({
    required double width,
    required double height,
    IconData? icon,            // optional
    String? title,             // optional
    String? subtitle,          // optional
    required VoidCallback onTap,
    String? imagePath,         // local asset path or network url
    bool isNetwork = false,
  }) {
    // container paddings used below must match the padding in the returned widget
    const double outerPadding = 0; // CHANGED: reduced from 10.0 to give image more room
    const double innerSpacing = 8.0;

    final bool hasText = (title?.isNotEmpty ?? false) || (subtitle?.isNotEmpty ?? false);

    // Reserve exact vertical space for top image and the text area so total never exceeds card height.
    // Text area uses a conservative fixed minimum and will grow if title/subtitle present.
    final double reservedTextArea = hasText ? 48.0 : 0.0; // safe room for 1 line title + optional subtitle

    // imageHeight computed from card height minus paddings & reserved text area.
    // CHANGED: subtract innerSpacing only when text exists to avoid extra gap for image-only cards
    final double imageHeight = (height - (outerPadding * 2) - (hasText ? innerSpacing : 0.0) - reservedTextArea)
        .clamp(44.0, height);

    final IconData usedIcon = icon ?? Icons.image;

    Widget imageWidget;
    if (imagePath != null) {
      if (isNetwork) {
        imageWidget = Image.network(
          imagePath,
          fit: BoxFit.cover, // ensure image covers the box
          width: double.infinity,
          height: imageHeight,
          alignment: Alignment.center,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: imageHeight,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
          errorBuilder: (ctx, err, st) => Container(
            width: double.infinity,
            height: imageHeight,
            color: Colors.grey.shade100,
            child: Center(child: Icon(usedIcon, size: 28, color: Colors.black26)),
          ),
        );
      } else {
        imageWidget = Image.asset(
          imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: imageHeight,
          gaplessPlayback: true, // <-- instantly displays old frame before new one
          cacheWidth: 400,       // <-- pre-decodes smaller image for faster render
          errorBuilder: (ctx, err, st) => Container(
            width: double.infinity,
            height: imageHeight,
            color: Colors.grey.shade100,
            child: Center(child: Icon(usedIcon, size: 28, color: Colors.black26)),
          ),
        );
      }
    } else {
      imageWidget = Container(
        width: double.infinity,
        height: imageHeight,
        color: Colors.grey.shade100,
        child: Center(child: Icon(usedIcon, size: 28, color: Colors.black54)),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(outerPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // image: fixed height computed above so it never overflows
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: imageWidget,
                ),
              ),

              // CHANGED: Remove extra gap for image-only cards so image fully covers top area
              if (hasText)
                SizedBox(height: innerSpacing / 1.2)
              else
                const SizedBox(height: 0),

              // optional text area: will occupy reservedTextArea (keeps layout predictable)
              if (hasText)
                SizedBox(
                  height: reservedTextArea,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null && title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      if (subtitle != null && subtitle.isNotEmpty)
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isPortrait = size.height >= size.width;

    final double cardHeight = (isPortrait
        ? size.height.clamp(560.0, 1000.0) * 0.25 * 1.2
        : size.height.clamp(360.0, 800.0) * 0.35 * 1.2)
        .toDouble();

    const int current = 1250;
    const int goal = 2500;
    final double progressRaw = current / goal;

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

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  SizedBox(height: vGapSmall * 0.5),
                                  const Text(
                                    'Calorie',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: vGapSmall * 1.4 * 1.1),
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
                                          // CHANGED: make calorie ring tappable
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (_) => const MealTrackingScreen()),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: vGapSmall * 1.3 * 1.2),
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
                                            // Note: nutrient cells are wrapped with GestureDetector below,
                                            // so we don't need onTap here unless you want ring-specific tap.
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

                                if (isWaterCell) {
                                  return GestureDetector(
                                    onTap: () => _showWaterPopup(context),
                                    child: content,
                                  );
                                } else {
                                  // CHANGED: make nutrient cells tappable and navigate to MealTrackingScreen
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const MealTrackingScreen()),
                                      );
                                    },
                                    child: content,
                                  );
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

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                            // Navigate to MealTrackingScreen when Add Meal is pressed
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MealTrackingScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18, color: Colors.black87),
                          label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: min(320, size.width * 0.48),
                        height: 48,
                        child: GradientBorderButton(
                          gradient: _appGradient,
                          onPressed: () => _showWaterPopup(context),
                          icon: const Icon(Icons.local_drink, size: 18, color: Colors.blue),
                          label: const Text('Add Water Intake', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ---------- Meal Tracking: 4 tappable feature cards (with images) ----------
              LayoutBuilder(builder: (context, layoutConstraints) {
                final double availableWidth = layoutConstraints.maxWidth;
                const double hSpacing = 12.0;
                final double cardWidth = (availableWidth - hSpacing) / 2;
                final double cardHeight = (cardWidth * 0.75).clamp(110.0, 180.0);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0, bottom: 8.0),
                      child: Text(
                        'Meal Discover',
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
                        // 1. Meal Planner (top-left)
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/meal_planner.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MealTrackingScreen())),
                        ),

                        // 2. Recommend for you (top-right)
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/recommend.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecommendScreen())),
                        ),

                        // 3. Recipes (bottom-left)
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/recipe.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RecipeScreen())),
                        ),

                        // 4. AI Meal Planner (bottom-right)
                        _featureCard(
                          width: cardWidth,
                          height: cardHeight,
                          imagePath: 'assets/images/ai_planner.png',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiMealPlannerScreen())),
                        ),
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
  if (p <= 0.2) return const Color(0xFFFFD54F);
  if (p <= 0.6) return const Color(0xFFFB8C00);
  if (p <= 1.0) return const Color(0xFFE53935);
  return const Color(0xFFB71C1C);
}

class _SolidRingWithIcon extends StatelessWidget {
  final double size, ringWidth, progress, iconSize;
  final Color baseColor, ringColor;
  final IconData icon;
  final VoidCallback? onTap; // CHANGED: optional tap callback

  const _SolidRingWithIcon({
    required this.size,
    required this.ringWidth,
    required this.progress,
    required this.baseColor,
    required this.ringColor,
    required this.icon,
    required this.iconSize,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Use Material + InkWell to get ripple effect when tapped
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size / 2)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
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
        ),
      ),
    );
  }
}

class _SolidRingPainter extends CustomPainter {
  final double progress;
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

/// -------------------- Meal card widget (unchanged except kcal tap) --------------------
// (unchanged, omitted here for brevity)
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
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade100,
              child: Icon(leadingIcon, size: 26, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  // kcal text tappable (navigates to MealTrackingScreen)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MealTrackingScreen()),
                      );
                    },
                    child: Text('$kcal kcal', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const SizedBox(height: 6),
                  LayoutBuilder(builder: (context, constraints) {
                    final double barWidth = constraints.maxWidth;
                    final double used = (kcal / 800).clamp(0.06, 1.0);
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
