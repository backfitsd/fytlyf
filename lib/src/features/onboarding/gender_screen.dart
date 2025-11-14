import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Local imports
import 'onboarding_controller.dart';
import 'widgets/onboarding_header.dart'; // ✅ new reusable header

class GenderScreen extends ConsumerStatefulWidget {
  static const routeName = '/onboarding/gender';
  const GenderScreen({super.key});

  @override
  ConsumerState<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends ConsumerState<GenderScreen> {
  String? selectedGender;

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Padding(
          // ✅ Reduced TOP padding above header
          padding: EdgeInsets.fromLTRB(
            isTablet ? 32 : 16,
            6, // << reduced from default to make header closer to top
            isTablet ? 32 : 16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ✅ Reusable OnboardingHeader (auto full width)
              OnboardingHeader(
                onBack: () {
                  // Go back safely to the welcome screen
                  context.go('/welcome');
                },
                onSkip: () {
                  // ✅ Use push instead of go so back returns to GenderScreen
                  context.push('/auth-entry');
                },
                progress: 0.125,
              ),

              const SizedBox(height: 25),
              Text(
                "What's your gender ?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 30),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Every step counts towards a healthier you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: _responsiveFont(context, 17),
                  color: Colors.black,
                ),
              ),
              const Spacer(),

              SizedBox(
                height: size.height * (isTablet ? 0.5 : 0.45),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      left: selectedGender == "Female"
                          ? size.width * 0.05
                          : (selectedGender == "Male"
                          ? size.width * 0.25
                          : size.width * 0.15),
                      top: selectedGender == "Male" ? 0 : size.height * 0.05,
                      child: _buildGenderOption(
                        gender: "Male",
                        image: "assets/images/male.png",
                        isSelected: selectedGender == "Male",
                        highlightColor: Colors.blue,
                        onTap: () {
                          setState(() => selectedGender = "Male");
                        },
                        size: size,
                      ),
                    ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      right: selectedGender == "Male"
                          ? size.width * 0.05
                          : (selectedGender == "Female"
                          ? size.width * 0.25
                          : size.width * 0.15),
                      top: selectedGender == "Female"
                          ? 0
                          : size.height * 0.05,
                      child: _buildGenderOption(
                        gender: "Female",
                        image: "assets/images/female.png",
                        isSelected: selectedGender == "Female",
                        highlightColor: Colors.pink,
                        onTap: () {
                          setState(() => selectedGender = "Female");
                        },
                        size: size,
                      ),
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

      // ✅ Updated NEXT button with extra space below it
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
                  onPressed: selectedGender == null
                      ? null
                      : () {
                    notifier.update({'gender': selectedGender});
                    context.push('/onboarding/goal');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedGender == null
                        ? Colors.grey
                        : const Color(0xFFFF3D00),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
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

              const SizedBox(height: 20), // ✅ Added spacing below NEXT
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderOption({
    required String gender,
    required String image,
    required bool isSelected,
    required Color highlightColor,
    required VoidCallback onTap,
    required Size size,
  }) {
    final isTablet = size.width > 600;
    final containerHeight = isSelected
        ? size.height * (isTablet ? 0.42 : 0.38)
        : size.height * (isTablet ? 0.32 : 0.28);
    final containerWidth = isSelected
        ? size.width * (isTablet ? 0.28 : 0.35)
        : size.width * (isTablet ? 0.22 : 0.25);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            height: containerHeight,
            width: containerWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    height: containerHeight,
                    width: containerWidth,
                    decoration: BoxDecoration(
                      color: highlightColor.withAlpha(230),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                Image.asset(image, fit: BoxFit.contain),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            gender,
            style: GoogleFonts.pottaOne(
              fontSize: 18,
              color: isSelected ? Colors.black : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
