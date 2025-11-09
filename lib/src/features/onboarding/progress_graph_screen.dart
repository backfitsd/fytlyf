// --- file: lib/src/features/onboarding/progress_graph_screen.dart ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/view/auth_entry_screen.dart';
import 'onboarding_controller.dart';

class ProgressGraphScreen extends ConsumerStatefulWidget {
  const ProgressGraphScreen({super.key});

  @override
  ConsumerState<ProgressGraphScreen> createState() =>
      _ProgressGraphScreenState();
}

class _ProgressGraphScreenState extends ConsumerState<ProgressGraphScreen>
    with TickerProviderStateMixin {
  final List<bool> _featureVisible = List.generate(6, (_) => false);
  final Map<int, double> _tiltAngles = {};

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < _featureVisible.length; i++) {
      Future.delayed(Duration(milliseconds: 180 * i), () {
        if (mounted) setState(() => _featureVisible[i] = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final scale = (w / 390).clamp(0.85, 1.25);

    final features = [
      {"emoji": "🏆", "title": "Challenges"},
      {"emoji": "👥", "title": "Social"},
      {"emoji": "💪", "title": "Workouts"},
      {"emoji": "📈", "title": "Progress"},
      {"emoji": "🤖", "title": "AI Coaching"},
      {"emoji": "🍎", "title": "Nutrition"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 20 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 8 * scale),
              Text(
                "Your Plan Is Ready 🎯",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 26 * scale,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 6 * scale),
              Text(
                "Welcome to your personalized FYT LYF journey — built for your goals.",
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14 * scale,
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(height: 24 * scale),

              // 🎯 Summary Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(22 * scale),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF3D00),
                      Color(0xFFFF6D00),
                      Color(0xFFFFA726),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22 * scale),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepOrangeAccent.withValues(alpha: 0.25),
                      blurRadius: 20 * scale,
                      offset: Offset(0, 8 * scale),
                    ),
                  ],
                ),
                child: _buildSummaryContent(data, scale),
              ),

              SizedBox(height: 36 * scale),

              Text(
                "Your FYT LYF Advantage",
                style: GoogleFonts.poppins(
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16 * scale),

              // ✅ Responsive Wrap (no overflow)
              Wrap(
                spacing: 16 * scale,
                runSpacing: 20 * scale,
                alignment: WrapAlignment.center,
                children: List.generate(features.length, (i) {
                  final f = features[i];
                  return AnimatedOpacity(
                    opacity: _featureVisible[i] ? 1 : 0,
                    duration: const Duration(milliseconds: 600),
                    child: _tiltingFeatureCard(
                      index: i,
                      emoji: f["emoji"] as String,
                      title: f["title"] as String,
                      scale: scale,
                    ),
                  );
                }),
              ),

              SizedBox(height: 36 * scale),

              SizedBox(
                width: double.infinity,
                height: 52 * scale,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const AuthEntryScreen(
                          initialTab: 'signup',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3D00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14 * scale),
                    ),
                    elevation: 4,
                    shadowColor: Colors.redAccent.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    "START YOUR JOURNEY",
                    style: GoogleFonts.poppins(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20 * scale),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Summary content with bold text
  Widget _buildSummaryContent(dynamic data, double scale) {
    String safe(Object? v) =>
        v?.toString().isNotEmpty == true ? v.toString() : '-';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.fitness_center_rounded,
                color: Colors.white, size: 26),
            SizedBox(width: 10 * scale),
            Text(
              "Personalized Summary",
              style: GoogleFonts.poppins(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        SizedBox(height: 16 * scale),
        _summaryRow("Goal", safe(data.goal)),
        _summaryRow("Current Weight", "${safe(data.weightKg)} kg"),
        _summaryRow("Target Weight", "${safe(data.targetWeightKg)} kg"),
        _summaryRow("Height", "${safe(data.heightCm)} cm"),
        _summaryRow("Experience", safe(data.experience)),
        _summaryRow("Weekly Goal", "${safe(data.weeklyGoal)} days"),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Using CustomPaint for gradient border (no BoxBorder.lerp issue)
  Widget _tiltingFeatureCard({
    required int index,
    required String emoji,
    required String title,
    required double scale,
  }) {
    final tiltAngle = _tiltAngles[index] ?? 0.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _tiltAngles[index] = -0.08),
      onTapUp: (_) => setState(() => _tiltAngles[index] = 0.0),
      onTapCancel: () => setState(() => _tiltAngles[index] = 0.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(tiltAngle),
        width: 100 * scale,
        height: 100 * scale,
        child: CustomPaint(
          painter: GradientBorderPainter(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF3D00), Color(0xFFFFA726)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            strokeWidth: 2,
            borderRadius: 22 * scale,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF9FAFB), Color(0xFFF3F4F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 10 * scale,
                  offset: Offset(0, 4 * scale),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  emoji,
                  style: TextStyle(fontSize: 32 * scale),
                ),
                SizedBox(height: 8 * scale),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13 * scale,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ CustomPainter-based gradient border (safe, smooth)
class GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double strokeWidth;
  final double borderRadius;

  GradientBorderPainter({
    required this.gradient,
    required this.strokeWidth,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
