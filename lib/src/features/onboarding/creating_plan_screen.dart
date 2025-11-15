// --- file: lib/src/features/onboarding/creating_plan_screen.dart ---
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_controller.dart';
import 'progress_graph_screen.dart';

class CreatingPlanScreen extends ConsumerStatefulWidget {
  static const routeName = '/creating-plan';
  const CreatingPlanScreen({super.key});

  @override
  ConsumerState<CreatingPlanScreen> createState() => _CreatingPlanScreenState();
}

class _CreatingPlanScreenState extends ConsumerState<CreatingPlanScreen>
    with TickerProviderStateMixin {
  final List<String> steps = [
    "Analyzing your fitness data",
    "Customizing your workout plan",
    "Optimizing nutrition & recovery",
    "Setting achievable goals",
    "Generating your personalized fitness plan",
  ];

  double progress = 0;
  bool merging = false;

  late AnimationController _hubController;
  late AnimationController _mergeController;
  late AnimationController _successController;
  late AnimationController _gradientController;
  late AnimationController _shimmerController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _hubController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _mergeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _successController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _gradientController =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _shimmerController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();

    _startAnimation();
  }

  void _startAnimation() {
    _timer = Timer.periodic(const Duration(milliseconds: 75), (timer) async {
      if (!mounted) return;
      setState(() {
        progress += 1;
        if (progress >= 100) {
          progress = 100;
          _timer?.cancel();
        }
      });

      if (progress >= 100 && !merging) {
        merging = true;
        _mergeController.forward();

        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) _successController.forward();
        });

        Future.delayed(const Duration(milliseconds: 3500), () async {
          await ref.read(onboardingProvider.notifier).save();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProgressGraphScreen()),
            );
          }
        });
      }

      _hubController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _hubController.dispose();
    _mergeController.dispose();
    _successController.dispose();
    _gradientController.dispose();
    _shimmerController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  LinearGradient _animatedGradient(double t) {
    final colors = [
      Color.lerp(const Color(0xFFFF0000), const Color(0xFFFF6D00), t * 0.8)!,
      Color.lerp(const Color(0xFFFF6D00), const Color(0xFFFFC107), t * 1.2)!,
    ];
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    int activeSteps = 0;
    if (progress >= 100) {
      activeSteps = 5;
    } else if (progress >= 90) {
      activeSteps = 5;
    } else if (progress >= 70) {
      activeSteps = 4;
    } else if (progress >= 50) {
      activeSteps = 3;
    } else if (progress >= 30) {
      activeSteps = 2;
    } else if (progress >= 10) {
      activeSteps = 1;
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            CustomPaint(size: size, painter: _ParticlePainter()),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Text(
                    "Creating Your Plan",
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([
                          _hubController,
                          _mergeController,
                          _successController,
                          _gradientController,
                          _shimmerController,
                        ]),
                        builder: (context, _) {
                          final animatedProgress = progress.clamp(0, 100);
                          final mergeValue = _mergeController.value;
                          final halo = _successController.value;
                          final showText = progress < 100;
                          final gradient = _animatedGradient(_gradientController.value);
                          final shimmerX =
                          Tween<double>(begin: -1, end: 2).evaluate(_shimmerController);

                          final double pulse = sin(halo * 2 * pi) * 0.5 + 0.5;

                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              if (halo > 0)
                                Container(
                                  width: 250 + 120 * pulse,
                                  height: 250 + 120 * pulse,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFFFF5722).withValues(alpha: 0.3 * (1 - pulse / 2)),
                                        Colors.transparent
                                      ],
                                      stops: const [0.4, 1.0],
                                    ),
                                  ),
                                ),
                              Transform.scale(
                                scale: 1 + sin(mergeValue * pi) * 0.25,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 135,
                                      height: 135,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: gradient,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFFF3D00).withValues(alpha: 0.45),
                                            blurRadius: 30,
                                            spreadRadius: 7,
                                          )
                                        ],
                                      ),
                                    ),
                                    ClipOval(
                                      child: ShaderMask(
                                        shaderCallback: (rect) {
                                          return LinearGradient(
                                            begin: Alignment(-1 + shimmerX, -1),
                                            end: Alignment(shimmerX, 1),
                                            colors: [
                                              Colors.white.withValues(alpha: 0.0),
                                              Colors.white.withValues(alpha: 0.4),
                                              Colors.white.withValues(alpha: 0.0),
                                            ],
                                            stops: const [0.2, 0.5, 0.8],
                                          ).createShader(rect);
                                        },
                                        blendMode: BlendMode.srcATop,
                                        child: Container(
                                          width: 135,
                                          height: 135,
                                          color: Colors.transparent,
                                        ),
                                      ),
                                    ),
                                    AnimatedOpacity(
                                      duration: const Duration(milliseconds: 150),
                                      opacity: showText ? 1.0 - mergeValue : 0.0,
                                      child: Text(
                                        "${animatedProgress.toInt()}%",
                                        style: GoogleFonts.poppins(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: const [
                                            Shadow(color: Colors.black26, blurRadius: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...List.generate(activeSteps, (index) {
                                final angle = (index / steps.length) * 2 * pi - pi / 2;
                                const radius = 120.0;
                                final fadeOut = 1.0 - mergeValue;
                                return Transform.translate(
                                  offset: Offset(
                                    radius * cos(angle) * (1.0 - mergeValue * 0.8),
                                    radius * sin(angle) * (1.0 - mergeValue * 0.8),
                                  ),
                                  child: Opacity(
                                    opacity: fadeOut,
                                    child: _StepBlock(
                                      number: index + 1,
                                      text: steps[index],
                                      gradient: gradient,
                                    ),
                                  ),
                                );
                              }),
                              if (halo > 0)
                                Transform.scale(
                                  scale: 0.8 + pulse * 0.3,
                                  child: Opacity(
                                    opacity: halo,
                                    child: Container(
                                      width: 135,
                                      height: 135,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: gradient,
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 52,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBlock extends StatelessWidget {
  final int number;
  final String text;
  final LinearGradient gradient;
  const _StepBlock({
    required this.number,
    required this.text,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.25),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            "$number",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 110,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Random _rand = Random();
  final int particleCount = 60;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFAB91).withValues(alpha: 0.15);
    for (int i = 0; i < particleCount; i++) {
      final dx = _rand.nextDouble() * size.width;
      final dy = _rand.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}