import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/experience_screen.dart';
import 'package:fytlyf/src/features/onboarding/weekly_goals_screen.dart';
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart';
import 'widgets/onboarding_header.dart';

class PreferenceScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/preference';
  const PreferenceScreen({super.key});

  @override
  ConsumerState<PreferenceScreen> createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends ConsumerState<PreferenceScreen> {
  final List<String> selectedPreferences = [];

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

    const double progress = 0.875;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingHeader(
                onBack: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ExperienceScreen(),
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
                "What do you prefer?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 30),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred workout type',
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
                    _buildPreferenceOption(
                      "Home Workout",
                      const Icon(Icons.home_filled,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildPreferenceOption(
                      "Gym",
                      const Icon(Icons.fitness_center,
                          color: Colors.white, size: 34),
                    ),
                    const SizedBox(height: 20),
                    _buildPreferenceOption(
                      "Outdoor",
                      const Icon(Icons.directions_run,
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
              onPressed: selectedPreferences.isEmpty
                  ? null
                  : () {
                final selectedString = selectedPreferences.join(', ');
                notifier.update({'preference': selectedString});
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const WeeklyGoalsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedPreferences.isEmpty
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
        ),
      ),
    );
  }

  Widget _buildPreferenceOption(String value, Icon icon) {
    final bool isSelected = selectedPreferences.contains(value);

    // ✅ Reverted original gradient colors
    const LinearGradient premiumGradient = LinearGradient(
      colors: [
        Color(0xFFFF3D00),
        Color(0xFFFF6D00),
        Color(0xFFFFA726),
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
      onTap: () => setState(() {
        isSelected
            ? selectedPreferences.remove(value)
            : selectedPreferences.add(value);
      }),
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
                color: const Color(0xFFFF6D00).withOpacity(0.4),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
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
