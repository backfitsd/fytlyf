import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Project imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/age_screen.dart';
import 'package:fytlyf/src/features/onboarding/gender_screen.dart';
import 'widgets/onboarding_header.dart';

class GoalScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/goal';
  const GoalScreen({super.key});

  @override
  ConsumerState<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends ConsumerState<GoalScreen> {
  String? selectedGoal;

  double _responsiveFont(BuildContext context, double base) {
    final size = MediaQuery.of(context).size;
    final shortest = size.width < size.height ? size.width : size.height;
    return base * (shortest / 420);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final notifier = ref.read(onboardingProvider.notifier);

    const double progress = 0.25;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingHeader(
                onBack: () => context.go(GenderScreen.routeName),
                // ✅ FIXED: Corrected the route for Auth screen
                onSkip: () => context.push('/auth-entry'),
                progress: progress,
              ),
              const SizedBox(height: 25),
              Text(
                "What's your main goal?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 30),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'We’ll personalize your plan accordingly.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 17),
                  color: Colors.black,
                ),
              ),
              const Spacer(),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildGoalOption(
                      "Lose Weight",
                      const Icon(Icons.local_fire_department,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildGoalOption(
                      "Build Muscle",
                      const Icon(Icons.fitness_center,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildGoalOption(
                      "Keep Fit",
                      const Icon(Icons.favorite,
                          color: Colors.white, size: 34),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selectedGoal == null
                  ? null
                  : () {
                notifier.update({'goal': selectedGoal});
                context.push(AgeScreen.routeName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                selectedGoal == null ? Colors.grey : const Color(0xFFFF3D00),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                "NEXT",
                style: GoogleFonts.roboto(
                  fontSize: _responsiveFont(context, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        ),
      ),
    );
  }

  // --- Smooth Premium Goal Option Card ---
  Widget _buildGoalOption(String goal, Icon icon) {
    final isSelected = selectedGoal == goal;

    // 🎨 Consistent premium gradient style
    const LinearGradient premiumGradient = LinearGradient(
      colors: [
        Color(0xFFFF3D00), // Bright Red
        Color(0xFFFF6D00), // Saffron
        Color(0xFFFFA726), // Light Yellow Tint
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final LinearGradient unselectedGradient = LinearGradient(
      colors: [Colors.grey.shade200, Colors.grey.shade100],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return GestureDetector(
      onTap: () {
        setState(() => selectedGoal = goal);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubicEmphasized,
        width: double.infinity,
        height: 95,
        transform: Matrix4.translationValues(0, isSelected ? -8.0 : 0.0, 0),
        decoration: BoxDecoration(
          gradient: isSelected ? premiumGradient : unselectedGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFFFF3D00) : Colors.transparent,
            width: 2,
          ),
        ),
        child: AnimatedOpacity(
          opacity: isSelected ? 1.0 : 0.9,
          duration: const Duration(milliseconds: 400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                child: icon,
              ),
              const SizedBox(width: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.black,
                ),
                child: Text(goal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
