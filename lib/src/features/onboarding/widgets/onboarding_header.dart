import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onSkip;
  final double progress; // 0.0–1.0 progress indicator

  const OnboardingHeader({
    super.key,
    required this.onBack,
    required this.onSkip,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final Color baseGrey = Colors.grey.shade200;
    final width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: baseGrey,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                iconSize: 20,
                splashRadius: 28,
                padding: EdgeInsets.zero,
                onPressed: onBack,
              ),
            ),
            SizedBox(
              width: 54,
              height: 54,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => CircularProgressIndicator(
                        strokeWidth: 6,
                        value: value,
                        backgroundColor: baseGrey,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                  ),
                  ClipOval(
                    child: Container(
                      width: 54,
                      height: 54,
                      color: baseGrey,
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(54, 54),
                          shape: const CircleBorder(),
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
