// file: lib/src/features/dashboard/view/dashboard_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:lottie/lottie.dart';
import 'widgets/bottom_nav_bar.dart'; // Ensure this file exists or remove this import if not needed
import 'package:flutter/cupertino.dart';

// ADDED: import paths for new screens
import 'package:fytlyf/src/features/dashboard/view/streak_screen.dart';
import 'package:fytlyf/src/features/dashboard/view/notification_screen.dart';
import 'package:fytlyf/src/features/dashboard/view/profile_screen.dart';

// ADDED: import for water screen
import '../nutritions/water_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late String greeting;
  late String motivationalLine;
  Timer? _greetingTimer;
  Timer? _autoSlideTimer;
  late PageController _pageController;
  int _currentPage = 0;
  Map<String, dynamic>? _userData;
  late AnimationController _animationController;

  double currentWater = 1.8; // liters
  final double goalWater = 3.0;

  static const List<Color> appGradient = BottomNavBar.appGradient;
  final int totalCards = 7;

  final List<String> motivationalLines = [
    "Push harder than yesterday.",
    "Dream big, work even harder.",
    "Make every rep count today.",
    "Small steps build great habits.",
    "Your only limit is your mind.",
    "Stronger today, unstoppable tomorrow.",
    "Discipline beats motivation every time.",
    "Win the morning, own the day.",
    "Progress, not perfection, every day.",
    "Stay consistent, results will follow.",
  ];

  // ---------- DISCOVER DATA ----------
  final List<Map<String, dynamic>> discoverItems = [
    {
      "icon": "🔥",
      "title": "Workout Tips",
      "desc": "Improve your strength & form"
    },
    {
      "icon": "🍳",
      "title": "Healthy Recipes",
      "desc": "Nutritious meals for your goals"
    },
    {
      "icon": "⚡",
      "title": "Challenges",
      "desc": "Push yourself every week"
    },
    {
      "icon": "🧘",
      "title": "Mindfulness",
      "desc": "Enhance focus & clarity"
    },
    {
      "icon": "⭐",
      "title": "Daily Habits",
      "desc": "Small steps, big results"
    },
  ];
  // -----------------------------------

  @override
  void initState() {
    super.initState();
    _generateGreeting();
    _setRandomMotivationalLine();
    _startGreetingUpdater();
    _fetchUserData();

    _pageController = PageController(
      viewportFraction: 0.96,
      initialPage: totalCards * 1000,
    );
    _currentPage = _pageController.initialPage;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  void _setRandomMotivationalLine() {
    final random = Random();
    motivationalLine =
    motivationalLines[random.nextInt(motivationalLines.length)];
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startGreetingUpdater() {
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _generateGreeting();
    });
  }

  void _generateGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      greeting = "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      greeting = "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      greeting = "Good Evening";
    } else {
      greeting = "Good Night";
    }
    setState(() {});
  }

  Widget _buildBigCard(int index, double cardHeight, double cardWidth) {
    return LayoutBuilder(builder: (context, constraints) {
      double adaptiveTitle = constraints.maxWidth * 0.05;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: cardWidth * 0.02),
        width: double.infinity,
        height: cardHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(cardWidth * 0.05),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: cardWidth * 0.04,
          vertical: cardHeight * 0.06,
        ),
        child: index == 0
            ? Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Today’s Plan",
                      style: TextStyle(
                          fontSize: adaptiveTitle,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  _buildPlanItem(Icons.fitness_center_rounded,
                      Colors.deepOrange, "Workout: Leg Day — 4 sets"),
                  const SizedBox(height: 8),
                  _buildPlanItem(Icons.restaurant_rounded, Colors.green,
                      "Meal Plan: Oats + Banana + Milk"),
                  const SizedBox(height: 8),
                  _buildPlanItem(Icons.alarm_rounded, Colors.blueAccent,
                      "Next: Meditation at 9 PM"),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Lottie.asset(
                'assets/animations/jumping_jack.json',
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
          ],
        )
            : const SizedBox.shrink(),
      );
    });
  }

  Widget _buildPlanItem(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // ---------- Discover card builder ----------
  Widget _buildDiscoverCard(
      double width, double height, String icon, String title, String desc) {
    final double scale = 0.7;
    final double cardW =
        (width * 0.96) * 0.6; // narrower card for good horizontal fit
    final double cardH = height * 0.20 * scale;

    return Container(
      width: cardW,
      margin: EdgeInsets.only(right: width * 0.04),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.05),
        border: Border.all(color: Colors.grey.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: SizedBox(
        height: cardH,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: TextStyle(fontSize: width * 0.08),
            ),
            SizedBox(height: height * 0.005),
            Text(
              title,
              style: TextStyle(
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87),
            ),
            SizedBox(height: height * 0.005),
            Text(
              desc,
              style: TextStyle(
                  fontSize: width * 0.032,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
  // -------------------------------------------

  void _showNutritionPopup(BuildContext context) {
    _showStyledPopup(
      context,
      title: "Nutrition",
      subtitle: "Today, Nov 10",
      icon: Icons.flash_on_rounded,
      color: Colors.orangeAccent,
      value: "1250/2500 g",
      metrics: [
        _metric(Icons.emoji_events_outlined, "Protein", "65/120g",
            Colors.blueAccent),
        _metric(Icons.star_border_rounded, "Carbs", "180/250g", Colors.green),
        _metric(Icons.circle_outlined, "Fat", "45/70g", Colors.orangeAccent),
      ],
    );
  }

  void _showStyledPopup(
      BuildContext context, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Color color,
        required String value,
        required List<Widget> metrics,
      }) {
    final width = MediaQuery.of(context).size.width;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: width * 0.08),
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87)),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54)),
                    ]),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 100,
                              width: 100,
                              child: CircularProgressIndicator(
                                value: 0.6,
                                strokeWidth: 7,
                                backgroundColor: color.withOpacity(0.15),
                                valueColor: AlwaysStoppedAnimation(color),
                              ),
                            ),
                            Icon(icon, size: 30, color: color),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(value,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: Column(children: metrics)),
                  ],
                ),
                const SizedBox(height: 28),
                _exploreButton(context),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showWaterPopup(BuildContext context) {
    double tempWater = currentWater;
    int selectedAmount = 250;
    const int maxAmount = 500;
    const int step = 10;

    final scrollController =
    FixedExtentScrollController(initialItem: selectedAmount ~/ step);

    showDialog(
      context: context,
      builder: (context) {
        final size = MediaQuery.of(context).size;
        final width = size.width;
        final height = size.height;

        final wheelItemExtent = height * 0.03;
        final wheelVisibleHeight = wheelItemExtent * 3;

        return StatefulBuilder(
          builder: (context, dialogSetState) {
            double progress = (tempWater / goalWater).clamp(0.0, 1.0);

            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: width * 0.08),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Hydration",
                          style: TextStyle(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "Today, Nov 10",
                          style: TextStyle(
                            fontSize: width * 0.035,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    Row(
                      children: [
                        /// LEFT SIDE – CIRCLE PROGRESS
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: width * 0.35,
                                    width: width * 0.35,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 9,
                                      backgroundColor:
                                      Colors.blueAccent.withOpacity(0.15),
                                      valueColor: const AlwaysStoppedAnimation(
                                        Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.water_drop_rounded,
                                    size: width * 0.06,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                              SizedBox(height: height * 0.015),
                              Text(
                                "${tempWater.toStringAsFixed(1)}L / ${goalWater.toStringAsFixed(1)}L",
                                style: TextStyle(
                                  fontSize: width * 0.037,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// RIGHT SIDE – WHEEL + BUTTONS
                        Expanded(
                          flex: 5,
                          child: Column(
                            children: [
                              Text(
                                "Select water (ml)",
                                style: TextStyle(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),

                              SizedBox(height: height * 0.01),

                              /// Wheel (3 visible items)
                              SizedBox(
                                height: wheelVisibleHeight,
                                child: ListWheelScrollView.useDelegate(
                                  controller: scrollController,
                                  itemExtent: wheelItemExtent,
                                  physics: const FixedExtentScrollPhysics(),
                                  overAndUnderCenterOpacity: 0.5,
                                  onSelectedItemChanged: (index) {
                                    dialogSetState(() {
                                      selectedAmount = index * step;
                                    });
                                  },
                                  childDelegate: ListWheelChildBuilderDelegate(
                                    childCount: (maxAmount ~/ step) + 1,
                                    builder: (context, index) {
                                      int value = index * step;
                                      bool isSelected = value == selectedAmount;

                                      return AnimatedDefaultTextStyle(
                                        duration:
                                        const Duration(milliseconds: 150),
                                        style: TextStyle(
                                          fontSize: isSelected
                                              ? width * 0.045
                                              : width * 0.038,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.blueAccent
                                              : Colors.black38,
                                        ),
                                        child: Text("$value ml"),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              SizedBox(height: height * 0.015),

                              /// - and + buttons (Option B)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      dialogSetState(() {
                                        tempWater -= selectedAmount / 1000;
                                        if (tempWater < 0) tempWater = 0;
                                        setState(() {
                                          currentWater = double.parse(
                                              tempWater.toStringAsFixed(1));
                                        });
                                      });
                                    },
                                    child: const Icon(
                                      Icons.remove_circle_outline,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  SizedBox(width: width * 0.06),
                                  InkWell(
                                    onTap: () {
                                      dialogSetState(() {
                                        tempWater += selectedAmount / 1000;
                                        if (tempWater > goalWater) {
                                          tempWater = goalWater;
                                        }
                                        setState(() {
                                          currentWater = double.parse(
                                              tempWater.toStringAsFixed(1));
                                        });
                                      });
                                    },
                                    child: const Icon(
                                      Icons.add_circle_outline,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: height * 0.02),

                    _exploreButton(
                      context,
                      onTap: () {
                        // Save temp value, close dialog and navigate to WaterScreen
                        setState(() {
                          currentWater = tempWater;
                        });
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WaterScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _metric(IconData icon, String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            height: 36,
            width: 36,
            child: CircularProgressIndicator(
              value: 0.7,
              strokeWidth: 4,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Icon(icon, size: 18, color: color),
        ]),
        const SizedBox(width: 10),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14))),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black54)),
      ]),
    );
  }

  // ✅ Updated gradient explore button (same for both popups)
  Widget _exploreButton(BuildContext context, {VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap ?? () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFFFF3D00),
                Color(0xFFFF6D00),
                Color(0xFFFFA726),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Text(
            "EXPLORE",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final userName = _userData?['username'] ?? 'User';

    final double cardHeight = height * 0.26 * 0.77;
    final double smallCardHeight = height * 0.16 * 0.7;
    final double smallIconSize = width * 0.06 * 0.7 * 1.4;
    final double equalCardWidth = width * 0.27;
    final double greetingLeftSpace = width * 0.015;
    final double usernameLeftSpace = greetingLeftSpace * 2;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(width * 0.06)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 18,
                        offset: const Offset(0, 6)),
                  ],
                ),
                padding: EdgeInsets.only(
                    left: width * 0.025,
                    right: width * 0.025,
                    top: 40,
                    bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: greetingLeftSpace),
                          child: Text(greeting,
                              style: TextStyle(
                                  fontSize: width * 0.035,
                                  fontWeight: FontWeight.w600)),
                        ),
                        Padding(
                          padding:
                          EdgeInsets.only(left: usernameLeftSpace, top: 2),
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                                colors: [
                                  Color(0xFFFF3D00),
                                  Color(0xFFFFA726)
                                ]).createShader(bounds),
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              userName,
                              style: TextStyle(
                                  fontSize: width * 0.05,
                                  fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ---------- TAPPABLE ICONS ----------
                    Row(
                      children: [
                        // Streak (fire) icon -> StreakScreen
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StreakScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.02),
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: Colors.orange,
                              size: width * 0.085,
                            ),
                          ),
                        ),

                        SizedBox(width: width * 0.01),

                        // Notification icon -> NotificationScreen
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.02),
                            child: Icon(
                              Iconsax.notification,
                              color: Colors.black87,
                              size: width * 0.07,
                            ),
                          ),
                        ),

                        SizedBox(width: width * 0.01),

                        // Profile icon -> ProfileScreen
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.02),
                            child: Icon(
                              Iconsax.profile_circle,
                              color: Colors.black87,
                              size: width * 0.085,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // ---------- END TAPPABLE ICONS ----------
                  ],
                ),
              ),

              // MOTIVATIONAL CARD
              Padding(
                padding: EdgeInsets.only(
                    top: height * 0.015, bottom: height * 0.012),
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: width * 0.02),
                  width: width * 0.96 * 0.95,
                  padding: EdgeInsets.symmetric(
                      vertical: height * 0.018 * 0.7, horizontal: width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(width * 0.05),
                    border: Border.all(
                        color: Colors.grey.withOpacity(0.3), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      motivationalLine,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: width * 0.04 * 0.7,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87),
                    ),
                  ),
                ),
              ),

              // BIG CARD CAROUSEL
              SizedBox(
                height: cardHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final realIndex = index % totalCards;
                    return _buildBigCard(realIndex, cardHeight, width);
                  },
                ),
              ),

              // SMALL CARDS
              Padding(
                padding: EdgeInsets.only(
                    left: width * 0.03, right: width * 0.03, top: height * 0.01),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        IconData iconData;
                        String title;
                        String value;
                        Color iconColor;
                        double targetValue;
                        VoidCallback? onTap;

                        switch (index) {
                          case 0:
                            iconData = Icons.local_fire_department_rounded;
                            title = "Calories";
                            value = "1,250 kcal";
                            iconColor = Colors.orangeAccent;
                            targetValue = 0.65;
                            onTap = () => _showNutritionPopup(context);
                            break;
                          case 1:
                            iconData = Icons.water_drop_rounded;
                            title = "Water";
                            value = "${currentWater.toStringAsFixed(1)} L";
                            iconColor = Colors.blueAccent;
                            targetValue =
                                (currentWater / goalWater).clamp(0, 1);
                            onTap = () => _showWaterPopup(context);
                            break;
                          default:
                            iconData = Icons.auto_graph_rounded;
                            title = "Progress";
                            value = "72%";
                            iconColor = Colors.green;
                            targetValue = 0.72;
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                              right: index < 2 ? width * 0.022 : 0),
                          child: GestureDetector(
                            onTap: onTap,
                            child: Container(
                              width: equalCardWidth,
                              height: smallCardHeight,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius.circular(width * 0.05),
                                border: Border.all(
                                    color: Colors.grey.withOpacity(0.15),
                                    width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(height: 8),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        height: smallIconSize * 1.6,
                                        width: smallIconSize * 1.6,
                                        child: CircularProgressIndicator(
                                          value: targetValue,
                                          backgroundColor:
                                          iconColor.withOpacity(0.15),
                                          valueColor:
                                          AlwaysStoppedAnimation(iconColor),
                                          strokeWidth: 5,
                                        ),
                                      ),
                                      Icon(iconData,
                                          size: smallIconSize,
                                          color: iconColor),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(title,
                                      style: TextStyle(
                                          fontSize: width * 0.032,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54)),
                                  const SizedBox(height: 2),
                                  Text(value,
                                      style: TextStyle(
                                          fontSize: width * 0.035,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87)),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.02),

              // DISCOVER SECTION
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Row(
                  children: [
                    Text("Discover",
                        style: TextStyle(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const Spacer(),
                  ],
                ),
              ),
              SizedBox(height: height * 0.015),

              // Discover Horizontal List
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: width * 0.05),
                child: Row(
                  children: discoverItems.map((item) {
                    return _buildDiscoverCard(
                      width,
                      height,
                      item["icon"],
                      item["title"],
                      item["desc"],
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: height * 0.05), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
