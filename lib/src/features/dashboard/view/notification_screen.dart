// file: lib/src/features/dashboard/view/notification_screen.dart
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // sample notifications (you can replace these with real data)
  final List<_NotifItem> _items = [
    _NotifItem(
      title: "Leg Day Reminder",
      subtitle: "Time for your workout!",
      time: "5 min ago",
      color: Colors.black87,
      icon: Icons.fitness_center,
      iconBg: Colors.orange.shade50,
      iconColor: Colors.orange,
    ),
    _NotifItem(
      title: "New Achievement!",
      subtitle: "You completed 5 consecutive workouts!",
      time: "5 hr ago",
      color: Colors.black87,
      icon: Icons.emoji_events,
      iconBg: Colors.orange.shade50,
      iconColor: Colors.orange,
      highlighted: true,
    ),
    _NotifItem(
      title: "Weekly Progress Update",
      subtitle: "You're 72% towards your goal!",
      time: "10 hrs ago",
      color: Colors.black87,
      icon: Icons.loop,
      iconBg: Colors.green.shade50,
      iconColor: Colors.green,
    ),
    _NotifItem(
      title: "Hydration Alert",
      subtitle: "Don't forget to log the goal!",
      time: "Yesterday",
      color: Colors.black87,
      icon: Icons.water_drop,
      iconBg: Colors.blue.shade50,
      iconColor: Colors.blue,
    ),
    _NotifItem(
      title: "App Update Available",
      subtitle: "Download an latest version.",
      time: "2 days ago",
      color: Colors.black87,
      icon: Icons.system_update,
      iconBg: Colors.blue.shade50,
      iconColor: Colors.blue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final horizPadding = 18.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header (matches dashboard style)
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizPadding, vertical: 18)
                    .copyWith(bottom: bottomInset + 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title section
                    const Text(
                      "Recent",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),

                    // Notification cards
                    Column(
                      children: List.generate(_items.length, (i) {
                        final item = _items[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: _buildNotificationCard(item),
                        );
                      }),
                    ),

                    const SizedBox(height: 8),

                    // Notification Preferences card with Clear All
                    _buildPreferencesCard(),

                    // extra spacing
                    SizedBox(height: 8 + bottomInset),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // floating bell button on bottom-right like reference (optional)
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // optional quick action
        },
        backgroundColor: const Color(0xFFFF6A00),
        child: const Icon(Icons.notifications, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildHeader(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(width * 0.06)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 18, offset: const Offset(0, 6)),
        ],
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
                "Notifications",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // open notification settings
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

  Widget _buildNotificationCard(_NotifItem item) {
    return Container(
      decoration: BoxDecoration(
        color: item.highlighted ? Colors.grey.shade200 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // icon box
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(item.icon, color: item.iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 12),

            // title + subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),

            // time label
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                item.time,
                style: const TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // small settings-like icon
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(child: Icon(Icons.notifications_active_outlined, color: Colors.black54)),
            ),

            const SizedBox(width: 12),

            // label
            const Expanded(
              child: Text(
                "Notification\nPreferences",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
              ),
            ),

            // Clear All action
            InkWell(
              onTap: () {
                // implement clear all
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Clear All",
                  style: TextStyle(color: Colors.orange.shade600, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

// simple model for notifications
class _NotifItem {
  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color color;
  final bool highlighted;

  _NotifItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.color,
    this.highlighted = false,
  });
}
