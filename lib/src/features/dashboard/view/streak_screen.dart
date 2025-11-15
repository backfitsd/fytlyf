// file: lib/src/features/dashboard/view/streak_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

class StreakScreen extends StatefulWidget {
  const StreakScreen({super.key});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> {
  // sample data — replace with real values
  final int currentStreak = 45;
  final int longestStreak = 60;
  final int totalWorkouts = 120;

  // weekly progress: true = done, false = not done
  final List<bool> weeklyProgress = [true, true, true, true, true, false, false];

  // achievements example (days thresholds)
  final List<int> achievementDays = [7, 30, 90];

  // sample history values for simple line chart
  final List<double> history = [24, 26, 27, 28, 32, 35, 37];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizPadding = 18.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      // content can extend into status bar area like Dashboard
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // App Bar (styled similar to dashboard header; top padding moved up)
            _buildTopBar(context, width),

            // content
            Expanded(
              child: SingleChildScrollView(
                // IMPORTANT: include bottom safe padding so nothing collides with device bottom
                padding: EdgeInsets.symmetric(horizontal: horizPadding, vertical: 18)
                    .copyWith(bottom: bottomInset + 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Flame card with days
                    _buildStreakHeaderCard(width - horizPadding * 2),

                    const SizedBox(height: 18),

                    // Weekly Progress title + card that contains circles inside white box
                    const Text(
                      "Weekly Progress",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildWeeklyProgressCard(),

                    const SizedBox(height: 20),

                    // Streak Statistics
                    const Text(
                      "Streak Statistics",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _buildStreakStatisticsCard(width - horizPadding * 2),

                    const SizedBox(height: 20),

                    // Achievements
                    const Text(
                      "Achievements",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildAchievementsRow(width - horizPadding * 2),

                    const SizedBox(height: 24),

                    // Streak History
                    const Text(
                      "Streak History",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    _buildHistoryCard(width - horizPadding * 2),

                    // extra spacer ensures last card isn't flush with bottom curve
                    SizedBox(height: 12 + bottomInset),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, double width) {
    // Using similar padding to Dashboard header so layout lines up visually
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(width * 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 10),
      child: Row(
        children: [
          // Back button
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.black87),
            ),
          ),

          // Title centered similar to dashboard (use expanded + center)
          const Expanded(
            child: Center(
              child: Text(
                "Streak",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),

          // Small notification icon on the right (tap can navigate)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // TODO: navigate to notifications screen if available
            },
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.notifications_none_rounded, size: 22, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakHeaderCard(double cardWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          // flame icon circle
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)]),
            ),
            child: const Center(
              child: Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 34),
            ),
          ),

          const SizedBox(width: 14),

          // big number + text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "$currentStreak",
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              const Text("Days", style: TextStyle(fontSize: 14, color: Colors.black54)),
            ],
          ),
          const Spacer(),

          // small placeholder for another icon or action (kept invisible to align)
          Opacity(opacity: 0.0, child: Icon(Icons.more_horiz)),
        ],
      ),
    );
  }

  // weekly progress in its own white card so circles stay inside the box
  Widget _buildWeeklyProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // horizontally scrollable row of circle items
          SizedBox(
            height: 86, // enough height for circle + label
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(weeklyProgress.length, (index) {
                  final done = weeklyProgress[index];
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 8 : 12, right: index == weeklyProgress.length - 1 ? 12 : 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _WeeklyCircle(done: done),
                        const SizedBox(height: 8),
                        Text(
                          _weekdayShort(index),
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          // optional helper text reserved
        ],
      ),
    );
  }

  String _weekdayShort(int index) {
    const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    return days[index % days.length];
  }

  Widget _buildStreakStatisticsCard(double width) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          _statItem(Icons.emoji_events_outlined, "Longest Streak", "$longestStreak Days"),
          _verticalDivider(),
          _statItem(Icons.whatshot_outlined, "Current Streak", "$currentStreak Days"),
          _verticalDivider(),
          _statItem(Icons.fitness_center, "Total Workouts", "$totalWorkouts"),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87))),
            ]),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 56, color: Colors.grey.withOpacity(0.12));
  }

  Widget _buildAchievementsRow(double totalWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(3, (i) {
        final days = achievementDays[i];
        final completed = (i < 2); // sample: first two completed
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
            child: _achievementCard(days: days, completed: completed),
          ),
        );
      }),
    );
  }

  Widget _achievementCard({required int days, required bool completed}) {
    final borderRadius = BorderRadius.circular(12.0);
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: completed ? null : const Color(0xFFF0F0F2),
        borderRadius: borderRadius,
        gradient: completed ? const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)]) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$days",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: completed ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Days",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: completed ? Colors.white70 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            completed ? "Completed!" : "Unlock Soon",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: completed ? Colors.white : Colors.black45,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHistoryCard(double width) {
    return Container(
      width: double.infinity,
      height: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6),
              child: CustomPaint(
                painter: _LineChartPainter(history),
                child: Container(),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // x-axis labels (simple placeholders)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text("201", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("202", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("2011", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("2016", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("2013", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("2012", style: TextStyle(color: Colors.black38, fontSize: 12)),
              Text("2013", style: TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// Simple circular weekly item with orange arc when completed
class _WeeklyCircle extends StatelessWidget {
  final bool done;

  const _WeeklyCircle({required this.done});

  @override
  Widget build(BuildContext context) {
    final size = 52.0;
    return SizedBox(
      height: size,
      width: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // outer shadow circle
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
          ),

          // progress arc (only visible if done)
          if (done)
            SizedBox(
              height: size,
              width: size,
              child: CustomPaint(
                painter: _ArcPainter(progress: 1.0, color: const Color(0xFFFF7A00)),
              ),
            ),

          // inner circle
          Container(
            height: size * 0.66,
            width: size * 0.66,
            decoration: BoxDecoration(
              color: done ? Colors.white : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: done
                  ? const Icon(Icons.check, size: 18, color: Color(0xFFFF7A00))
                  : Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Paints an orange arc around the circle
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.08;
    final rect = Offset.zero & size;
    final startAngle = -pi / 2;
    final sweep = 2 * pi * progress;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(rect.deflate(stroke / 2), startAngle, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress || old.color != color;
}

// Very basic line chart painter to mimic the orange progression
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paintLine = Paint()
      ..color = const Color(0xFFFF7A00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..shader = LinearGradient(colors: [const Color(0xFFFF7A00).withOpacity(0.12), Colors.white])
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final minV = values.reduce(min);
    final maxV = values.reduce(max);
    final denom = (maxV - minV) == 0 ? 1 : (maxV - minV);

    // map values to points
    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i] - minV) / denom;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    // path for line
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // fill path for the area under the curve
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // little dots
    final dotPaint = Paint()..color = const Color(0xFFFF7A00);
    for (final p in points) {
      canvas.drawCircle(p, 3.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) => old.values != values;
}
