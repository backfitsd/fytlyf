import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late String greeting;
  Timer? _greetingTimer;
  int streakDays = 5;

  @override
  void initState() {
    super.initState();
    _generateSmartGreeting();
    _startGreetingUpdater();
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    super.dispose();
  }

  void _startGreetingUpdater() {
    // Refresh every minute
    _greetingTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _generateSmartGreeting();
    });
  }

  void _generateSmartGreeting() {
    final hour = DateTime.now().hour;
    final random = Random();

    List<String> morning = [
      "Good Morning, Aditya 🌅",
      "Rise and Shine, Aditya!",
      "Let's Own the Day, Aditya!",
      "Start Strong, Aditya 💪"
    ];
    List<String> afternoon = [
      "Good Afternoon, Aditya ☀️",
      "Keep It Going, Aditya!",
      "Stay Focused, Aditya 🔥",
      "Push Through, Aditya!"
    ];
    List<String> evening = [
      "Good Evening, Aditya 🌇",
      "Unwind and Reflect, Aditya",
      "You Did Great Today, Aditya 💪",
      "Stay Balanced, Aditya 🌙"
    ];
    List<String> night = [
      "Good Night, Aditya 🌙",
      "Rest and Recover, Aditya",
      "Recharge for Tomorrow 🔋",
      "Sleep Well, Aditya 💤"
    ];
    List<String> extras = [
      "Welcome Back, Aditya 🔥",
      "Keep the Streak Alive, Aditya 💪",
      "You're Doing Amazing, Aditya 👏",
      "Stay Consistent, Aditya ⚡"
    ];

    String newGreeting;
    if (hour >= 5 && hour < 12) {
      newGreeting = morning[random.nextInt(morning.length)];
    } else if (hour >= 12 && hour < 17) {
      newGreeting = afternoon[random.nextInt(afternoon.length)];
    } else if (hour >= 17 && hour < 21) {
      newGreeting = evening[random.nextInt(evening.length)];
    } else {
      newGreeting = night[random.nextInt(night.length)];
    }

    // Occasionally show motivational one (20 % chance)
    if (random.nextInt(5) == 0) {
      newGreeting = extras[random.nextInt(extras.length)];
    }

    if (mounted) {
      setState(() => greeting = newGreeting);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          // ---------------- HEADER ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.menu_rounded, color: Colors.black87),
                  const SizedBox(width: 10),

                  // 🔥 Animated greeting text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 700),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                      final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0.0, 0.4), end: Offset.zero)
                          .animate(
                          CurvedAnimation(parent: animation, curve: Curves.easeOut));
                      return FadeTransition(
                        opacity: animation,
                        child:
                        SlideTransition(position: offsetAnimation, child: child),
                      );
                    },
                    child: Text(
                      greeting,
                      key: ValueKey<String>(greeting),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ]),
                Row(children: [
                  Row(children: [
                    const Icon(Icons.local_fire_department_rounded,
                        color: Colors.orange),
                    const SizedBox(width: 4),
                    Text("$streakDays",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87)),
                  ]),
                  const SizedBox(width: 12),
                  const Icon(Icons.notifications_none_rounded,
                      color: Colors.black54),
                  const SizedBox(width: 12),
                  const Icon(Icons.settings_outlined, color: Colors.black54),
                ])
              ],
            ),
          ),

          // ---------------- MY PLAN SECTION ----------------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("My Plan",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.black87)),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF7043).withValues(alpha: 0.15),
                        const Color(0xFFE53935).withValues(alpha: 0.05)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  border: Border.all(color: const Color(0xFFFF7043), width: 0.6)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/pushup.png',
                    fit: BoxFit.cover,
                  )),
            ),
          ),

          const SizedBox(height: 18),

          // ---------------- MOTIVATION QUOTE ----------------
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              "Push yourself, because no one else is going to do it for you.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4),
            ),
          ),
          Container(
            height: 2,
            width: 120,
            decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF7043)])),
          ),

          const SizedBox(height: 18),

          // ---------------- PROGRESS RINGS ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _ProgressRing(
                    title: "Calories", value: 1200, goal: 2000, color: 0xFFFF7043),
                _ProgressRing(
                    title: "Water Intake",
                    value: 5,
                    goal: 8,
                    color: 0xFF42A5F5,
                    unit: "Glasses"),
                _ProgressRing(
                    title: "Today's Progress",
                    value: 70,
                    goal: 100,
                    color: 0xFF26C6DA,
                    unit: "%"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ---------------- ACTIVITY GRID ----------------
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                physics: const BouncingScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.4,
                children: const [
                  _ActivityCard(
                      icon: Icons.directions_run,
                      title: "Cardio",
                      color: 0xFFFF7043),
                  _ActivityCard(
                      icon: Icons.self_improvement,
                      title: "Yoga",
                      color: 0xFF42A5F5),
                  _ActivityCard(
                      icon: Icons.flash_on,
                      title: "HIIT",
                      color: 0xFFE53935),
                  _ActivityCard(
                      icon: Icons.accessibility_new,
                      title: "Flexibility",
                      color: 0xFF26C6DA),
                  _ActivityCard(
                      icon: Icons.fitness_center,
                      title: "Toning",
                      color: 0xFFFF7043),
                  _ActivityCard(
                      icon: Icons.spa, title: "Recovery", color: 0xFF8E24AA),
                ],
              ),
            ),
          ),
        ]),
      ),

      // ---------------- BOTTOM NAV ----------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
            ],
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(22))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: const [
            _NavItem(icon: Icons.home_rounded, label: "Home", active: true),
            _NavItem(icon: Icons.fitness_center_rounded, label: "Workouts"),
            _NavItem(icon: Icons.people_alt_outlined, label: "Social"),
            _NavItem(icon: Icons.restaurant_menu_rounded, label: "Meals"),
            _NavItem(icon: Icons.emoji_events_outlined, label: "Challenges"),
          ],
        ),
      ),
    );
  }
}

// ---------------- COMPONENTS ----------------
class _ProgressRing extends StatelessWidget {
  final String title;
  final int value;
  final int goal;
  final int color;
  final String unit;
  const _ProgressRing(
      {required this.title,
        required this.value,
        required this.goal,
        required this.color,
        this.unit = "kcal",
        super.key});

  @override
  Widget build(BuildContext context) {
    final progress = (value / goal).clamp(0.0, 1.0);
    return Column(
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Color(color)),
              ),
              Text(
                unit == "%" ? "$value$unit" : "$value",
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(title,
            style: const TextStyle(
                fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500))
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int color;
  const _ActivityCard(
      {required this.icon, required this.title, required this.color, super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300, width: 0.8),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
              color: Color(color).withValues(alpha: 0.1),
              shape: BoxShape.circle),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Color(color), size: 28),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87))
      ],
    ),
  );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavItem(
      {required this.icon, required this.label, this.active = false, super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon,
          size: 24,
          color: active
              ? const Color(0xFFFF7043)
              : Colors.grey.withValues(alpha: 0.8)),
      const SizedBox(height: 4),
      Text(label,
          style: TextStyle(
              fontSize: 11,
              color: active
                  ? const Color(0xFFE53935)
                  : Colors.grey.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600))
    ],
  );
}
