import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:iconsax/iconsax.dart';
import 'widgets/bottom_nav_bar.dart';

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
    motivationalLine = motivationalLines[random.nextInt(motivationalLines.length)];
  }

  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
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

  Future<void> _logoutAndGoToAuth() async {
    try {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
  }

  // ---------- 🏋️ BUILD BIG CARD WITH TODAY'S PLAN (Adaptive) ----------
  Widget _buildBigCard(int index, double cardHeight, double cardWidth) {
    final userData = _userData ?? {};
    final gender = (userData['gender'] ?? '').toString().toLowerCase();
    final imagePath =
    gender == 'female' ? 'assets/images/female.png' : 'assets/images/male.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        double adaptiveFont = constraints.maxWidth * 0.036;
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🗓️ Left content - Adaptive Today’s Plan
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Today’s Plan",
                      style: TextStyle(
                        fontSize: adaptiveTitle,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: cardHeight * 0.03),
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.fitness_center_rounded,
                              color: Colors.deepOrange,
                              size: adaptiveFont * 1.3),
                          SizedBox(width: cardWidth * 0.02),
                          Expanded(
                            child: Text(
                              "Workout: Leg Day — 4 sets of squats",
                              style: TextStyle(
                                fontSize: adaptiveFont,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: cardHeight * 0.015),
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.restaurant_rounded,
                              color: Colors.green,
                              size: adaptiveFont * 1.3),
                          SizedBox(width: cardWidth * 0.02),
                          Expanded(
                            child: Text(
                              "Meal Plan: Breakfast — Oats + Banana + Milk",
                              style: TextStyle(
                                fontSize: adaptiveFont,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: cardHeight * 0.015),
                    Flexible(
                      child: Row(
                        children: [
                          Icon(Icons.alarm_rounded,
                              color: Colors.blueAccent,
                              size: adaptiveFont * 1.3),
                          SizedBox(width: cardWidth * 0.02),
                          Expanded(
                            child: Text(
                              "Next: Meditation at 9 PM",
                              style: TextStyle(
                                fontSize: adaptiveFont,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: cardHeight * 0.03),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        "View Details →",
                        style: TextStyle(
                          fontSize: adaptiveFont,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🧍 Right image (unchanged, adaptive)
              Expanded(
                flex: 2,
                child: Image.asset(
                  imagePath,
                  height: constraints.maxHeight * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          )
              : const SizedBox.shrink(),
        );
      },
    );
  }

  // ---------- 🧱 MAIN BUILD ----------
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final userName = _userData?['username'] ?? 'User';

    final double cardHeight = height * 0.26 * 0.77;
    final double smallCardHeight = height * 0.16 * 0.7;
    final double smallIconSize = width * 0.06 * 0.7 * 1.4;
    final double greetingLeftPadding = width * 0.02;
    final double usernameLeftPadding = greetingLeftPadding * 2;
    final double equalCardWidth = width * 0.27;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(width * 0.06)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: greetingLeftPadding),
                          child: Text(
                            greeting,
                            style: TextStyle(
                              fontSize: width * 0.035,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        SizedBox(height: height * 0.004),
                        Padding(
                          padding: EdgeInsets.only(left: usernameLeftPadding),
                          child: ShaderMask(
                            shaderCallback: (Rect bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFF3D00),
                                  Color(0xFFFF6D00),
                                  Color(0xFFFFA726),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            blendMode: BlendMode.srcIn,
                            child: Text(
                              userName,
                              style: TextStyle(
                                fontSize: width * 0.05,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [
                                Color(0xFFFFE082),
                                Color(0xFFFFB300),
                                Color(0xFFFF6D00),
                                Color(0xFFFF3D00),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.srcIn,
                          child: Icon(Icons.local_fire_department_rounded,
                              size: width * 0.085),
                        ),
                        SizedBox(width: width * 0.035),
                        Icon(Iconsax.notification,
                            size: width * 0.07, color: Colors.black87),
                        SizedBox(width: width * 0.025),
                        Icon(Iconsax.profile_circle,
                            size: width * 0.085, color: Colors.black87),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ---------- MOTIVATIONAL CARD ----------
            Padding(
              padding: EdgeInsets.only(top: height * 0.015, bottom: height * 0.012),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: width * 0.02),
                width: width * 0.96 * 0.95,
                padding: EdgeInsets.symmetric(
                  vertical: height * 0.018 * 0.7,
                  horizontal: width * 0.04,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(width * 0.04),
                  border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    motivationalLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: width * 0.04 * 0.7,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),

            // ---------- BIG CARD CAROUSEL ----------
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

            // ---------- SMALL CARDS ----------
            Padding(
              padding: EdgeInsets.only(
                left: width * 0.03,
                right: width * 0.03,
                top: height * 0.01,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  IconData iconData;
                  String title;
                  String value;
                  Color iconColor;
                  double targetValue;

                  switch (index) {
                    case 0:
                      iconData = Icons.local_fire_department_rounded;
                      title = "Calories";
                      value = "1,250 kcal";
                      iconColor = Colors.orangeAccent;
                      targetValue = 0.65;
                      break;
                    case 1:
                      iconData = Icons.water_drop_rounded;
                      title = "Water";
                      value = "1.8 L";
                      iconColor = Colors.blueAccent;
                      targetValue = 0.45;
                      break;
                    default:
                      iconData = Icons.auto_graph_rounded;
                      title = "Progress";
                      value = "72%";
                      iconColor = Colors.green;
                      targetValue = 0.72;
                  }

                  return Padding(
                    padding: EdgeInsets.only(right: index < 2 ? width * 0.022 : 0),
                    child: Container(
                      width: equalCardWidth,
                      height: smallCardHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(width * 0.045),
                        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              double animatedValue =
                                  _animationController.value * targetValue;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    height: smallCardHeight * 0.45 * 0.8,
                                    width: smallCardHeight * 0.45 * 0.8,
                                    child: CircularProgressIndicator(
                                      value: animatedValue,
                                      strokeWidth: 5,
                                      backgroundColor:
                                      iconColor.withOpacity(0.15),
                                      valueColor:
                                      AlwaysStoppedAnimation(iconColor),
                                    ),
                                  ),
                                  Icon(iconData,
                                      size: smallIconSize,
                                      color: iconColor.withOpacity(0.9)),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: height * 0.008),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: width * 0.03,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: height * 0.003),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: width * 0.033,
                              fontWeight: FontWeight.w700,
                              color: iconColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ---------- FOOTER ----------
            Expanded(
              child: Center(
                child: Text(
                  "Dashboard Basee Screen",
                  style: TextStyle(
                    fontSize: width * 0.035,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
