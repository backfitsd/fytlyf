import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Updated imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/weight_height_screen.dart';
import 'package:fytlyf/src/features/onboarding/goal_screen.dart';
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart';
import 'widgets/onboarding_header.dart'; // ✅ new shared header

class AgeScreen extends ConsumerStatefulWidget {
  static const String routeName = '/onboarding/age';
  const AgeScreen({super.key});

  @override
  ConsumerState<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends ConsumerState<AgeScreen> {
  final int minAge = 13;
  final int maxAge = 100;
  late FixedExtentScrollController _controller;
  late int _selectedAge;

  @override
  void initState() {
    super.initState();
    _selectedAge = 27;
    _controller = FixedExtentScrollController(initialItem: _selectedAge - minAge);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get accentRed => const Color(0xFFE53935);

  double responsiveFont(BuildContext context, double base) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final shortest = width < height ? width : height;
    return base * (shortest / 420);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Shared OnboardingHeader with 37.5% progress
              OnboardingHeader(
                onBack: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GoalScreen()),
                  );
                },
                onSkip: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            AuthEntryScreen()
                    ),
                  );
                },
                progress: 0.375,
              ),

              const SizedBox(height: 32),

              Text(
                'How old are you?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: responsiveFont(context, 30),
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Your age helps us personalize your journey!',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  color: Colors.grey.shade700,
                  fontSize: responsiveFont(context, 16),
                ),
              ),

              Expanded(
                child: Center(
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100.withAlpha(178),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CupertinoPicker(
                      key: const ValueKey('age_picker'),
                      scrollController: _controller,
                      itemExtent: 48,
                      magnification: 1.2,
                      squeeze: 1.1,
                      useMagnifier: true,

                      // ✅ Gradient border overlay (fully transparent center — text remains visible)
                      selectionOverlay: const _SelectionOverlay(),

                      onSelectedItemChanged: (index) {
                        setState(() {
                          _selectedAge = minAge + index;
                        });
                      },

                      children: List.generate(
                        maxAge - minAge + 1,
                            (i) {
                          final age = minAge + i;
                          final isSelected = age == _selectedAge;

                          return Center(
                            child: Text(
                              '$age',
                              style: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.black
                                    : Colors.grey.shade600,
                                fontSize: isSelected ? 26 : 20,
                                fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ← MATCHED to GoalScreen: add spacer + small gap before bottomNavigationBar
              const Spacer(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    notifier.update({'age': _selectedAge.toDouble()});
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WeightHeightScreen(),
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
                      fontWeight: FontWeight.bold,
                      fontSize: responsiveFont(context, 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 00),
        height: 50,

        // ✅ Transparent background (MUST for visibility)
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),

        // ✅ Gradient BORDER applied using ShaderMask (text stays visible)
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
                color: Colors.white, // → becomes gradient by shader
              ),
            ),
          ),
        ),
      ),
    );
  }
}
