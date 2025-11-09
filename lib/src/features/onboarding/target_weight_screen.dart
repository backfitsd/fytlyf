// --- file: lib/src/features/onboarding/target_weight_screen.dart ---
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;

// Local imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/experience_screen.dart';
import 'package:fytlyf/src/features/onboarding/weight_height_screen.dart';
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart';
import 'widgets/onboarding_header.dart'; // ✅ Shared header

class TargetWeightScreen extends ConsumerStatefulWidget {
  static const String routeName = '/onboarding/target-weight';
  const TargetWeightScreen({super.key});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen>
    with SingleTickerProviderStateMixin {
  final double minWeight = 30.0;
  final double maxWeight = 200.0;
  late FixedExtentScrollController _controller;
  late double _selectedWeight;
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _selectedWeight = 75.0;
    final initialIndex = (_selectedWeight - minWeight).round();
    _controller = FixedExtentScrollController(initialItem: initialIndex);

    // Animation controller for shimmer gradient movement
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  Color get bg => Colors.white;
  Color get textPrimary => Colors.black;

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    final heightMeters = ((draft.heightCm ?? 170).toDouble()) / 100.0;
    final currentWeight = (draft.weightKg ?? _selectedWeight).toDouble();
    final bmi =
    heightMeters > 0 ? currentWeight / (heightMeters * heightMeters) : 0.0;

    String getBmiLabel(double v) {
      if (v == 0) return '—';
      if (v < 18.5) return 'Underweight';
      if (v < 25) return 'Healthy';
      if (v < 30) return 'Overweight';
      return 'Obese';
    }

    List<Color> getBmiGradient(double v) {
      if (v == 0) return [Colors.grey.shade300, Colors.grey.shade400];
      if (v < 18.5) {
        return const [Color(0xFFFFA726), Color(0xFFFF7043)]; // orange
      } else if (v < 25) {
        return const [Color(0xFF00C853), Color(0xFF64DD17)]; // green
      } else if (v < 30) {
        return const [Color(0xFFFFC107), Color(0xFFFFA000)]; // amber
      } else {
        return const [Color(0xFFD50000), Color(0xFFFF1744)]; // red
      }
    }

    Color getBmiAccent(double v) {
      if (v == 0) return Colors.grey;
      if (v < 18.5) return const Color(0xFFFF7043);
      if (v < 25) return const Color(0xFF00C853);
      if (v < 30) return const Color(0xFFFFA000);
      return const Color(0xFFD50000);
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Shared header
              OnboardingHeader(
                onBack: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WeightHeightScreen(),
                    ),
                  );
                },
                onSkip: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthEntryScreen(),
                    ),
                  );
                },
                progress: 0.625,
              ),
              const SizedBox(height: 20),

              // Title + Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'What is Your Target Weight?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fitness is not a destination, it’s a lifestyle.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      color: textPrimary.withAlpha(178),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ✅ Picker
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 250,
                    child: CupertinoPicker(
                      key: const ValueKey('weight_picker'),
                      scrollController: _controller,
                      itemExtent: 48,
                      magnification: 1.2,
                      squeeze: 1.1,
                      useMagnifier: true,
                      selectionOverlay: const _SelectionOverlay(),
                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedWeight = minWeight + index.toDouble();
                        });
                      },
                      children: List.generate(
                        (maxWeight - minWeight + 1).round(),
                            (i) {
                          final weight = minWeight + i.toDouble();
                          final isSelected = weight == _selectedWeight;
                          return Center(
                            child: Text(
                              '${weight.toStringAsFixed(0)} kg',
                              style: GoogleFonts.roboto(
                                color: isSelected
                                    ? Colors.black
                                    : textPrimary.withAlpha(127),
                                fontSize: isSelected ? 26 : 20,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ BMI + NEXT
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _gradientController,
                builder: (context, _) {
                  return _AnimatedGradientBmiCard(
                    bmi: bmi,
                    label: getBmiLabel(bmi),
                    gradientColors: getBmiGradient(bmi),
                    accentColor: getBmiAccent(bmi),
                    subtitle:
                    'Based on weight ${currentWeight.round()} kg & height ${(heightMeters * 100).round()} cm',
                    animationValue: _gradientController.value,
                  );
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    notifier.update({
                      'targetWeightKg': _selectedWeight.toInt(),
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ExperienceScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'NEXT',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ---------- Components ---------- */

// ✅ Animated Gradient BMI Card (Full Color Mode + Animated Gradient)
class _AnimatedGradientBmiCard extends StatelessWidget {
  final double bmi;
  final String label;
  final List<Color> gradientColors;
  final Color accentColor;
  final String subtitle;
  final double animationValue;

  const _AnimatedGradientBmiCard({
    required this.bmi,
    required this.label,
    required this.gradientColors,
    required this.accentColor,
    required this.subtitle,
    required this.animationValue,
  });

  @override
  Widget build(BuildContext context) {
    final gradientShift = (animationValue * 2 * math.pi);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment(
              math.cos(gradientShift) * 0.8, math.sin(gradientShift) * 0.8),
          end: Alignment(
              math.cos(gradientShift + math.pi) * 0.8,
              math.sin(gradientShift + math.pi) * 0.8),
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  accentColor.withOpacity(0.7),
                  accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              bmi == 0 ? '—' : bmi.toStringAsFixed(1),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Body Mass Index',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bmi == 0 ? '—' : bmi.toStringAsFixed(1)} • $label',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ Gradient picker overlay identical to AgeScreen
class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        height: 50,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFFFF3D00),
                Color(0xFFFF6D00),
                Color(0xFFFFA726),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                width: 3,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
