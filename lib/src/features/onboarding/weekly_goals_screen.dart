import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Local imports
import 'package:fytlyf/src/features/onboarding/onboarding_controller.dart';
import 'package:fytlyf/src/features/onboarding/preference_screen.dart';
import 'package:fytlyf/src/features/onboarding/creating_plan_screen.dart';
import 'package:fytlyf/src/features/auth/view/auth_entry_screen.dart';
import 'widgets/onboarding_header.dart';

class WeeklyGoalsScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/weekly-goals';
  const WeeklyGoalsScreen({super.key});

  @override
  ConsumerState<WeeklyGoalsScreen> createState() => _WeeklyGoalsScreenState();
}

class _WeeklyGoalsScreenState extends ConsumerState<WeeklyGoalsScreen> {
  int? selectedDays;

  double _responsiveFont(BuildContext context, double base) {
    final size = MediaQuery.of(context).size;
    final shortest =
    size.width < size.height ? size.width : size.height;
    return base * (shortest / 420);
  }

  // ✅ Same premium gradient as Goal Screen
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OnboardingHeader(
                onBack: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const PreferenceScreen(),
                    ),
                  );
                },
                onSkip: () {
                  // ✅ FIXED: use push instead of pushReplacement so back works
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AuthEntryScreen(),
                    ),
                  );
                },
                progress: 1,
              ),

              const SizedBox(height: 30),

              Text(
                'Set your weekly goal',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 28),
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'We recommend training at least 3 days weekly for better results.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 16),
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // ✅ Weekly Training Days heading
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('🎯', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      "Weekly training days",
                      style: GoogleFonts.roboto(
                        fontSize: _responsiveFont(context, 16),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ✅ WEEKLY SELECTION with Goal Screen style but ORIGINAL SIZE
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: List.generate(7, (index) {
                  final int day = index + 1;
                  final bool isSelected = selectedDays == day;

                  final LinearGradient unselectedGradient = LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  );

                  return GestureDetector(
                    onTap: () => setState(() => selectedDays = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubicEmphasized,
                      width: 72,
                      height: 72,
                      transform:
                      Matrix4.translationValues(0, isSelected ? -8.0 : 0.0, 0),
                      decoration: BoxDecoration(
                        gradient:
                        isSelected ? premiumGradient : unselectedGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: const Color(0xFFFF6D00).withValues(alpha: 0.40),
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
                          color: isSelected
                              ? const Color(0xFFFF3D00)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 350),
                        opacity: isSelected ? 1.0 : 0.9,
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                            child: Text("$day"),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),

      // ✅ NEXT button (unchanged)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: selectedDays == null
                  ? null
                  : () {
                notifier.update({'weeklyGoal': selectedDays});

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreatingPlanScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedDays == null
                    ? Colors.grey
                    : const Color(0xFFFF3D00),
                elevation: selectedDays == null ? 0 : 4,
                shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'NEXT',
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
}