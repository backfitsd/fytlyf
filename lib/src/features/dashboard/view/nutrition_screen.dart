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
      if (p <= 0.6)  return "Great balance.\nFuel up and stay consistent.";
      if (p <= 0.85) return "Strong progress.\nAlign the next meal to your goal.";
      if (p <= 1.0)  return "Right on target.\nTiny tweaks make perfect days.";
      return "You’re above target.\nGo lighter now and hydrate well.";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              // ---------- Header ----------
              Card(
                elevation: 5,
                color: Colors.white,
                shadowColor: Colors.black.withOpacity(0.06),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('Nutrition', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                      Text('Today, Nov 10', style: TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
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

                                  // Push the motivational text to the very bottom of the card
                                  const Spacer(),

                                  // Motivational line at the BOTTOM of the 1st card
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, bottom: 2.0),
                                    child: Text(
                                      _motivation(progressRaw),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      maxLines: 3, // will wrap like your example
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

                              Widget buildCell(String title, IconData icon, double progress,
                                  String value, Color color) {
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
                                        iconSize:
                                        (ringSize * 0.42).clamp(16.0, ringSize * 0.55).toDouble(),
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
                                    buildCell('Protein', Iconsax.cup, 0.55, '65/120g',
                                        const Color(0xFF42A5F5)),
                                    const SizedBox(width: hGap),
                                    buildCell('Carbs', Iconsax.ranking, 0.72, '180/250g',
                                        const Color(0xFF66BB6A)),
                                  ],
                                ),
                                const SizedBox(height: vGap),
                                Row(
                                  children: [
                                    buildCell('Fat', Iconsax.coffee, 0.48, '45/70g',
                                        const Color(0xFFFB8C00)),
                                    const SizedBox(width: hGap),
                                    buildCell('Water', Iconsax.glass, 0.60, '1.2/2.5L',
                                        const Color(0xFF64B5FF)),
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