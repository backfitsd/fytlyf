import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/target_weight_screen.dart';
import 'package:fytlyf/src/features/onboarding/preference_screen.dart';
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart';
import 'widgets/onboarding_header.dart';

class ExperienceScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/experience';
  const ExperienceScreen({super.key});

  @override
  ConsumerState<ExperienceScreen> createState() => _ExperienceScreenState();
}

class _ExperienceScreenState extends ConsumerState<ExperienceScreen> {
  String? selectedExperience;

  double _responsiveFont(BuildContext context, double base) {
    final size = MediaQuery.of(context).size;
    final shortest = size.width < size.height ? size.width : size.height;
    return base * (shortest / 420);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    const double progress = 0.75;

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
                onBack: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TargetWeightScreen(),
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
                progress: progress,
              ),
              const SizedBox(height: 25),
              Text(
                "What is your experience level?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 30),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How many push-ups can you do at one time?',
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
                    _buildExperienceOption(
                      "Beginner (0–10)",
                      const Icon(Icons.flag_circle,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildExperienceOption(
                      "Intermediate (11–30)",
                      const Icon(Icons.fitness_center,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildExperienceOption(
                      "Advanced (30+)",
                      const Icon(Icons.local_fire_department,
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
      // ------------------ MATCHED bottomNavigationBar ------------------
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min, // important: don't expand
            children: [
              SizedBox(
                height: 56,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedExperience == null
                      ? null
                      : () {
                    notifier.update({'experience': selectedExperience});
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PreferenceScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedExperience == null
                        ? Colors.grey
                        : const Color(0xFFFF3D00),
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
              // ← This extra gap below the button matches GoalScreen's spacing
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExperienceOption(String value, Icon icon) {
    final isSelected = selectedExperience == value;

    // ✅ Reverted to original premium gradient colors
    const LinearGradient premiumGradient = LinearGradient(
      colors: [
        Color(0xFFFF3D00), // Bright Red
        Color(0xFFFF6D00), // Saffron
        Color(0xFFFFA726), // Yellow tint
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
      onTap: () => setState(() => selectedExperience = value),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
