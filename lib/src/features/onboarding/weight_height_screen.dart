import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/target_weight_screen.dart';
import 'package:fytlyf/src/features/onboarding/age_screen.dart';

// ✅ FIX: Alias import to avoid class conflict
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart' as auth;

import 'widgets/onboarding_header.dart'; // ✅ shared header

class WeightHeightScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/weightHeight';
  const WeightHeightScreen({super.key});

  @override
  ConsumerState<WeightHeightScreen> createState() =>
      _WeightHeightScreenState();
}

class _WeightHeightScreenState extends ConsumerState<WeightHeightScreen> {
  late double weightKg;
  late int heightCm;

  final double minWeight = 30;
  final double maxWeight = 200;
  final int minHeight = 120;
  final int maxHeight = 230;

  late FixedExtentScrollController weightController;
  late FixedExtentScrollController heightController;

  final Color blue = const Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    weightKg = 75.0;
    heightCm = 175;

    weightController = FixedExtentScrollController(
        initialItem: ((weightKg - minWeight) * 10).round());
    heightController =
        FixedExtentScrollController(initialItem: heightCm - minHeight);
  }

  @override
  void dispose() {
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  Widget _buildRuler({
    required int itemCount,
    required double itemExtent,
    required FixedExtentScrollController controller,
    required Function(int) onSelectedItemChanged,
    required double minValue,
    required bool isWeight,
    required int majorStep,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                Colors.white.withAlpha(0),
                Colors.white.withAlpha(0),
                Colors.white,
              ],
              stops: const [0, 0.05, 0.95, 1],
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: RotatedBox(
            quarterTurns: -1,
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: itemExtent,
              onSelectedItemChanged: onSelectedItemChanged,
              useMagnifier: false,
              squeeze: 1,
              diameterRatio: 10,
              looping: false,
              children: List.generate(itemCount, (i) {
                final isMajor = i % majorStep == 0;
                final value = minValue + (isWeight ? i / 10 : i.toDouble());
                return RotatedBox(
                  quarterTurns: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isMajor)
                        Text(
                          value.toStringAsFixed(0),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E88E5),
                          ),
                        ),
                      Container(
                        width: isMajor ? 3 : 1.5,
                        height: isMajor ? 35 : 15,
                        color: const Color(0xFF1E88E5),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              onBack: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AgeScreen()),
                );
              },
              onSkip: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    // ✅ FIXED: alias class avoids conflict
                    builder: (_) => const auth.AuthEntryScreen(),
                  ),
                );
              },
              progress: 0.5,
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'Let us know you better',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Let us know you better to help boost your\nworkout results',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black.withAlpha(178),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Weight',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _BigNumber(
                      value: weightKg.toStringAsFixed(1),
                      suffix: 'kg',
                      color: blue,
                    ),

                    const SizedBox(height: 12),

                    _buildRuler(
                      itemCount:
                      ((maxWeight - minWeight) * 10 + 1).toInt(),
                      itemExtent: 20,
                      controller: weightController,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          weightKg = minWeight + index / 10;
                        });
                      },
                      minValue: minWeight,
                      isWeight: true,
                      majorStep: 10,
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Height',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _BigNumber(
                      value: heightCm.toString(),
                      suffix: 'cm',
                      color: blue,
                    ),

                    const SizedBox(height: 12),

                    _buildRuler(
                      itemCount: maxHeight - minHeight + 1,
                      itemExtent: 20,
                      controller: heightController,
                      onSelectedItemChanged: (index) {
                        setState(() {
                          heightCm = minHeight + index;
                        });
                      },
                      minValue: minHeight.toDouble(),
                      isWeight: false,
                      majorStep: 5,
                    ),

                    SizedBox(height: width > 400 ? 40 : 28),
                  ],
                ),
              ),
            ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      notifier.update({
                        'weightKg': weightKg.round(),
                        'heightCm': heightCm,
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TargetWeightScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'NEXT',
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/* ---------- UI PARTS ---------- */

class _BigNumber extends StatelessWidget {
  final String value;
  final String suffix;
  final Color color;

  const _BigNumber({
    required this.value,
    required this.suffix,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          suffix,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}