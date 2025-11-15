// file: lib/src/features/dashboard/view/streak_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

/// Animated & Accessible Streak Screen
/// Header design matches notification_screen.dart (rounded bottom, shadow, back button, settings).
/// Buttons use the same "Explore" gradient as your Dashboard screen.
/// - Self-contained demo UI for a "Streak" screen with animations and accessibility labels.
/// - Replace mock data with Firestore / Riverpod as needed.
class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with SingleTickerProviderStateMixin {
  // Accent used for non-button elements (circle, active bar). Buttons use gradient below.
  static const Color _accentColor = Color(0xFFE53935);
  static const Color cardBg = Color(0xFFF8F8F9);

  // Explore gradient (copied from DashboardScreen)
  static const LinearGradient exploreGradient = LinearGradient(
    colors: [
      Color(0xFFFF3D00),
      Color(0xFFFF6D00),
      Color(0xFFFFA726),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- MOCK DATA --- replace with real data source (Firestore / Riverpod)
  /// Index 0 = most recent day (today).
  static final List<bool> _mockActivityLast14Days = [
    true, // today
    true,
    true,
    true,
    false,
    true,
    true,
    true,
    true,
    true,
    true,
    false,
    true,
    true,
  ];
  // --- END MOCK DATA ---

  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _computeCurrentStreak(List<bool> activity) {
    int count = 0;
    for (final day in activity) {
      if (day) count++;
      else break;
    }
    return count;
  }

  int _computeBestStreak(List<bool> activity) {
    int best = 0;
    int running = 0;
    for (final day in activity) {
      if (day) {
        running++;
        if (running > best) best = running;
      } else {
        running = 0;
      }
    }
    return best;
  }

  double _progressTowardTarget(int current, int target) {
    if (target <= 0) return 0.0;
    return (current / target).clamp(0.0, 1.0);
  }

  // Gradient button helper (used in Log Now & Daily Habit)
  Widget _gradientButton({
    required String text,
    required VoidCallback onPressed,
    double radius = 10,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 12),
    TextStyle textStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
  }) {
    return Semantics(
      button: true,
      label: text,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: exploreGradient,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(text, style: textStyle.copyWith(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _mockActivityLast14Days;
    final currentStreak = _computeCurrentStreak(activity);
    final bestStreak = _computeBestStreak(activity);
    const target = 7;
    final progress = _progressTowardTarget(currentStreak, target);
    final totalActiveDays = activity.where((e) => e).length;

    final horizPadding = 18.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      // Removed the floatingActionButton per your request
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header (matches notification style)
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizPadding, vertical: 18)
                    .copyWith(bottom: bottomInset + 28),
                child: Column(
                  children: [
                    // Top card: circular progress + stats
                    _buildTopCard(context, currentStreak, bestStreak, target, progress),
                    const SizedBox(height: 16),
                    // Weekly activity chart
                    _buildActivityCard(activity, totalActiveDays),
                    const SizedBox(height: 16),
                    // Tips and CTA
                    _buildTipsCard(context, currentStreak, target),
                    const SizedBox(height: 12),
                    // Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 8 + 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header copied / adapted from notification_screen.dart (same visual design)
  Widget _buildHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(width * 0.06)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      padding: EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 10),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.black87),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Streak",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // open settings
            },
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.settings_outlined, size: 22, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCard(BuildContext context, int current, int best, int target, double progress) {
    final semanticLabel = 'Current streak: $current days. Best streak: $best days. Weekly target: $target days.';

    return Semantics(
      label: semanticLabel,
      value: '$current of $target days',
      child: Card(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
          child: Row(
            children: [
              // Circular progress (animated)
              SizedBox(
                width: 110,
                height: 110,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final animatedProgress = _anim.value * progress;
                    return CustomPaint(
                      painter: _CircularStreakPainter(progress: animatedProgress, strokeWidth: 12, accent: _accentColor),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$current', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('days', style: TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // Stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Streak', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 6),
                    Text('$current days', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _smallStat('Best', '$best'),
                        const SizedBox(width: 14),
                        _smallStat('Target (wk)', '$target'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: 'Progress toward weekly target',
                      value: '${(progress * 100).round()} percent',
                      child: LinearProgressIndicator(
                        value: progress * _anim.value,
                        minHeight: 8,
                        backgroundColor: Colors.white,
                        color: _accentColor,
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

  Widget _smallStat(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _buildActivityCard(List<bool> activity, int totalActiveDays) {
    final chartLabel = 'Activity for last ${activity.length} days. $totalActiveDays active days.';

    return Semantics(
      container: true,
      label: chartLabel,
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(children: const [
                Expanded(child: Text('Last 14 days', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                Text('Activity', style: TextStyle(color: Colors.black54)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _BarSparklinePainter(activity: activity, accent: _accentColor, reveal: _anim.value),
                      child: Container(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                _legendDot(_accentColor, 'Active'),
                const SizedBox(width: 12),
                _legendDot(Colors.grey.shade300, 'Inactive'),
                const Spacer(),
                Text('$totalActiveDays active days', style: const TextStyle(color: Colors.black54)),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(children: [
      Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
    ]);
  }

  Widget _buildTipsCard(BuildContext context, int current, int target) {
    final daysToTarget = (target - current).clamp(0, target);
    final semanticsTip = daysToTarget > 0
        ? 'Need $daysToTarget more day${daysToTarget > 1 ? 's' : ''} to reach your $target day weekly target.'
        : 'You reached your weekly target. Keep going to build long-term habits.';

    return Semantics(
      label: 'Tips: $semanticsTip',
      child: Card(
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
          child: Row(children: [
            const Icon(Icons.rocket_launch, color: _accentColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Keep the momentum', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  daysToTarget > 0
                      ? 'Just $daysToTarget more day${daysToTarget > 1 ? 's' : ''} to reach your ${target}-day weekly target.'
                      : 'You reached your weekly target! Keep going to create long-term habits.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            // Log now button uses gradient
            _gradientButton(
              text: 'Log now',
              onPressed: () {
                // TODO: navigate to today's workout or quick log
              },
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              radius: 10,
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Outlined "View Progress" kept as outlined but with gradient border accent
        Expanded(
          child: Semantics(
            button: true,
            label: 'View Progress. Opens detailed progress and reports.',
            child: OutlinedButton(
              onPressed: () {
                // TODO: open reports/progress detail
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.orange.withOpacity(0.18)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.white,
              ),
              child: const Text('View Progress', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // "Daily Habit" uses gradient button
        Expanded(
          child: _gradientButton(
            text: 'Daily Habit',
            onPressed: () {
              // TODO: show tips or small streak-maintaining tasks
            },
            radius: 10,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }
}

/// Circular progress painter for showing streak progress.
class _CircularStreakPainter extends CustomPainter {
  final double progress; // 0.0 - 1.0 (animated)
  final double strokeWidth;
  final Color accent;

  _CircularStreakPainter({required this.progress, this.strokeWidth = 10, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
        colors: [accent, accent.withOpacity(0.9)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final start = -pi / 2;
    final sweep = 2 * pi * progress;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _CircularStreakPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.accent != accent;
  }
}

/// Bar sparkline painter for last N days activity.
/// Supports `reveal` animation factor (0..1).
class _BarSparklinePainter extends CustomPainter {
  final List<bool> activity;
  final Color accent;
  final double reveal; // 0..1 driving height reveal (for animation)

  _BarSparklinePainter({required this.activity, required this.accent, required this.reveal});

  @override
  void paint(Canvas canvas, Size size) {
    final paintActive = Paint()..color = accent;
    final paintInactive = Paint()..color = Colors.grey.shade300;
    final n = activity.length;
    if (n == 0) return;

    final barWidth = size.width / (n * 1.6);
    final gap = (size.width - n * barWidth) / (n - 1);
    final maxBarHeight = size.height * 0.9;

    for (int i = 0; i < n; i++) {
      final x = i * (barWidth + gap);
      final isActive = activity[i];

      // Staggered reveal: compute interval per bar so they pop in sequence.
      final start = (i / n) * 0.6; // start earlier for earlier bars
      final end = start + 0.4;
      final t = ((reveal - start) / (end - start)).clamp(0.0, 1.0);
      final easeT = Curves.easeOut.transform(t);

      final h = (isActive ? maxBarHeight : maxBarHeight * 0.28) * easeT;
      final rect = Rect.fromLTWH(x, size.height - h, barWidth, h);
      final r = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(r, isActive ? paintActive : paintInactive);

      if ((i % 3) == 0) {
        final tp = TextPainter(
          text: TextSpan(text: _labelForIndex(i), style: TextStyle(color: Colors.black54, fontSize: 10)),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x, size.height + 4));
      }
    }
  }

  String _labelForIndex(int index) {
    if (index == 0) return 'T';
    if (index == 1) return 'Y';
    if (index == 2) return '2d';
    return '${index}d';
  }

  @override
  bool shouldRepaint(covariant _BarSparklinePainter oldDelegate) {
    return oldDelegate.activity != activity || oldDelegate.accent != accent || oldDelegate.reveal != reveal;
  }
}
