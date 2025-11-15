// file: lib/src/features/dashboard/view/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // sample user data (replace with real values)
  final String userName = "User";
  final double weightKg = 75;
  final int heightCm = 180;
  final double bmi = 23.1;

  final int caloriesBurned = 500;
  final int workouts = 15;
  final int goalProgress = 80;

  final List<String> achievementLabels = [
    "Consistent Week",
    "5K Run",
    "Run",
    "Planks",
    "Strength Builder",
    "Food Log"
  ];

  final List<IconData> achievementIcons = [
    Icons.emoji_events_rounded,
    Icons.directions_run,
    Icons.directions_run,
    Icons.accessibility_new,
    Icons.fitness_center,
    Icons.restaurant_menu,
  ];

  final List<Map<String, dynamic>> settings = [
    {"title": "Account Details", "icon": Icons.person_outline},
    {"title": "Fitness Goals", "icon": Icons.track_changes_outlined},
    {"title": "Connected Devices", "icon": Icons.devices_outlined},
    {"title": "Privacy Policy", "icon": Icons.privacy_tip_outlined},
    {"title": "Help & Support", "icon": Icons.help_outline},
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizPadding = 18.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(width),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizPadding, vertical: 18)
                    .copyWith(bottom: bottomInset + 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + Edit button
                    Center(child: _buildAvatarSection(width)),
                    const SizedBox(height: 16),

                    // User Statistics card
                    const Text("User Statistics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    _buildUserStatsCard(),

                    const SizedBox(height: 18),

                    // Activity Summary
                    const Text("Activity Summary", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildActivitySummaryRow(width),

                    const SizedBox(height: 18),

                    // Achievement badges
                    const Text("Achievement Badges", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildBadgesRow(),

                    const SizedBox(height: 18),

                    // Settings
                    const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    _buildSettingsList(),

                    // final spacer to avoid bottom overflow
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

  Widget _buildHeader(double width) {
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
            borderRadius: BorderRadius.circular(12),
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.black87),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text("Profile", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // open profile settings
            },
            child: const Padding(
              padding: EdgeInsets.all(6.0),
              child: Icon(Icons.settings_outlined, size: 22, color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(double width) {
    // reduce avatar vertical footprint slightly to avoid pushing down content too much
    return Column(
      children: [
        Container(
          height: 106,
          width: 106,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF3D00)]),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: Container(
              height: 90,
              width: 90,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: const Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 36, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6A00),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 4,
          ),
          child: const Text("Edit Profile", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildUserStatsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _statTile(icon: Icons.monitor_weight_outlined, title: "Weight:", value: "${weightKg.toInt()} kg"),
          _verticalDivider(),
          _statTile(icon: Icons.height_outlined, title: "Height:", value: "$heightCm cm"),
          _verticalDivider(),
          _statTile(icon: Icons.favorite_outline, title: "BMI", value: bmi.toStringAsFixed(1)),
        ],
      ),
    );
  }

  Widget _statTile({required IconData icon, required String title, required String value}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
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

  Widget _buildActivitySummaryRow(double screenWidth) {
    // calculate card width so three cards fit without forcing overflow
    final horizPadding = 18.0;
    final gap = 12.0;
    final availableWidth = screenWidth - (horizPadding * 2) - (gap * 2);
    final cardWidth = (availableWidth / 3).clamp(80.0, 150.0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _activityCard(
          width: cardWidth,
          icon: Icons.local_fire_department_rounded,
          title: "Calories Burned",
          value: "$caloriesBurned kcal",
          gradient: const LinearGradient(colors: [Color(0xFFFF8A50), Color(0xFFFF5C00)]),
        ),
        const SizedBox(width: 12),
        _activityCard(
          width: cardWidth,
          icon: Icons.fitness_center,
          title: "Workouts",
          value: "$workouts",
          gradient: const LinearGradient(colors: [Color(0xFFFF7A00), Color(0xFFFF6A00)]),
        ),
        const SizedBox(width: 12),
        _activityCard(
          width: cardWidth,
          icon: Icons.donut_large,
          title: "Goal Progress",
          value: "$goalProgress%",
          gradient: const LinearGradient(colors: [Color(0xFFFFAB40), Color(0xFFFF6A00)]),
        ),
      ],
    );
  }

  Widget _activityCard({
    required double width,
    required IconData icon,
    required String title,
    required String value,
    required Gradient gradient,
  }) {
    // use a fixed width + constrained content so text doesn't expand vertically
    return Container(
      width: width,
      height: 110,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Icon(icon, color: Colors.white, size: 22)),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesRow() {
    return SizedBox(
      height: 86,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(achievementLabels.length, (i) {
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 6 : 12, right: i == achievementLabels.length - 1 ? 12 : 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Center(
                      child: Icon(achievementIcons[i % achievementIcons.length], color: Colors.orangeAccent, size: 28),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 72,
                    child: Text(
                      achievementLabels[i],
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    return Column(
      children: List.generate(settings.length, (i) {
        final s = settings[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6))],
            ),
            child: ListTile(
              leading: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Icon(s['icon'], color: Colors.black54)),
              ),
              title: Text(s['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right, color: Colors.black38),
              onTap: () {},
            ),
          ),
        );
      }),
    );
  }
}
