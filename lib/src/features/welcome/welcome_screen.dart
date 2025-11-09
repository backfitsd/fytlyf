import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  static const String routeName = '/welcome';

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    final double logoFontSize = size.width * 0.09;
    final double taglineFontSize = size.width * 0.035;
    final double loginTextFontSize = size.width * 0.035;
    final double buttonFontSize = size.width * 0.05;
    final double buttonWidth = size.width * 0.9;
    final double buttonHeight = size.height * 0.055;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                "assets/images/welcome_bg.png",
                fit: BoxFit.cover,
              ),

              // Foreground content
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top logo + tagline
                    Padding(
                      padding: const EdgeInsets.only(left: 30, top: 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "FYT LYF",
                            style: GoogleFonts.pottaOne(
                              fontSize: logoFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                    blurRadius: 25.0,
                                    color: Colors.redAccent,
                                    offset: Offset(0, 0)),
                                Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.white70,
                                    offset: Offset(0, 0)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "FEEL YOUR TRANSFORMATION",
                            style: GoogleFonts.roboto(
                              fontSize: taglineFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "LOVE YOUR FITNESS",
                            style: GoogleFonts.roboto(
                              fontSize: taglineFontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Bottom CTA
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              // ✅ Use push instead of go for back navigation
                              context.push('/onboarding/gender');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15.0),
                              ),
                              minimumSize: Size(buttonWidth, buttonHeight),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                            ),
                            child: Text(
                              "GET STARTED",
                              style: GoogleFonts.roboto(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already a member?",
                                style: GoogleFonts.roboto(
                                  fontSize: loginTextFontSize,
                                  color: Colors.white,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // ✅ Use push instead of go so back works
                                  context.push('/auth-entry');
                                },
                                child: Text(
                                  " Log in",
                                  style: GoogleFonts.roboto(
                                    fontSize: loginTextFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
