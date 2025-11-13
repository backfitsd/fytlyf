// file: lib/src/features/dashboard/view/nutrition_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

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

    // Common button style
    final ButtonStyle btnStyle = OutlinedButton.styleFrom(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(color: Colors.black.withOpacity(0.08)),
      foregroundColor: Colors.black87,
      minimumSize: const Size(64, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

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
                // make Material transparent so gradient from Container is visible
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF3D00),
                        Color(0xFFFF6D00),
                        Color(0xFFFFA726),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                          style: TextStyle(fontSize: 15, color: Colors.white70),
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

                              // Progress ring sizing (already +1.2x from previous step)
                              double ringSize =
                              (min(cw, ch) * 0.65 * 1.2 * 1.2).clamp(90.0, min(cw * 0.98, ch * 0.98));
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

                                  // GAP below title increased by 1.1x
                                  SizedBox(height: vGapSmall * 1.4 * 1.1),

                                  // Big circular progress (centered)
                                  Center(
                                    child: _SolidRingWithIcon(
                                      size: ringSize,
                                      ringWidth: ringWidth,
                                      progress: progressRaw.clamp(0.0, 1.0),
                                      baseColor: const Color(0xFFE8F2FF),
                                      ringColor: calorieColor,
                                      icon: Iconsax.flash,
                                      iconSize: iconSize,
                                    ),
                                  ),

                                  // GAP below ring increased by 1.2x
                                  SizedBox(height: vGapSmall * 1.3 * 1.2),

                                  // Progress text
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '$current/$goal g',
                                      style: const TextStyle(
                                        fontSize: 19,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),

                                  // push motivation to bottom
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

                              final double ringSize =
                              (min(colWidth, rowHeight) * 0.7).clamp(44.0, 120.0).toDouble();
                              final double ringWidth = (ringSize * 0.07).clamp(3.0, 6.0).toDouble();
                              final double titleSize = (ringSize * 0.26).clamp(12.0, 17.0).toDouble();
                              final double valueSize =
                              (ringSize * 0.23 * 0.8 * 1.1).clamp(9.0, 15.0).toDouble();

                              Widget buildCell(String title, IconData icon, double progress, String value, Color color) {
                                return SizedBox(
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
                                      _SolidRingWithIcon(
                                        size: ringSize,
                                        ringWidth: ringWidth,
                                        progress: progress,
                                        baseColor: const Color(0xFFE8F2FF),
                                        ringColor: color,
                                        icon: icon,
                                        iconSize: (ringSize * 0.42).clamp(16.0, ringSize * 0.55).toDouble(),
                                      ),
                                      const SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          value,
                                          style: TextStyle(fontSize: valueSize, color: Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
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
                                    buildCell('Water', Iconsax.glass, 0.60, '1.2/2.5L', const Color(0xFF64B5FF)),
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
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        // limit width so it doesn't overflow in narrow screens
                        width: min(160, size.width * 0.36),
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: implement add meal
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Meal', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: btnStyle,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Align right button under the nutrients card (flex 6)
                  Expanded(
                    flex: 6,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: min(320, size.width * 0.53), // wider button as in your screenshot
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: implement add water intake
                          },
                          icon: const Icon(Icons.local_drink, size: 18, color: Colors.blue,),
                          label: const Text('Add Water Intake', style: TextStyle(fontWeight: FontWeight.w600)),
                          style: btnStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
            ],
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
    required this.progress, // 0..1
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
