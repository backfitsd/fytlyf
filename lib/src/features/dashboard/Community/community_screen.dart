// file: lib/src/features/social/view/community_screen.dart
import 'package:flutter/material.dart';

/// Example social/community screen file containing:
/// - CommunityScreen (self-contained header)
/// - CommunityScreenWithAppHeader (uses your AppHeader widget)
///
/// Replace mock data with Firestore + provider logic as needed.

class CommunityUser {
  final String id;
  final String displayName;
  final String username;
  final String avatarUrl;
  final bool isPrivate;
  bool isFollowing;
  bool requestPending;

  CommunityUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.avatarUrl,
    this.isPrivate = true,
    this.isFollowing = false,
    this.requestPending = false,
  });
}

final List<CommunityUser> _mockUsers = [
  CommunityUser(
    id: 'u1',
    displayName: 'Anita Sharma',
    username: 'anita_sh',
    avatarUrl: '', // leave empty for initials fallback
    isPrivate: false,
  ),
  CommunityUser(
    id: 'u2',
    displayName: 'Rahul Verma',
    username: 'rahul_v',
    avatarUrl: '',
    isPrivate: true,
  ),
  CommunityUser(
    id: 'u3',
    displayName: 'Sana Khan',
    username: 'sanak_fit',
    avatarUrl: '',
    isPrivate: false,
  ),
  CommunityUser(
    id: 'u4',
    displayName: 'Dev Gupta',
    username: 'dev.g',
    avatarUrl: '',
    isPrivate: true,
  ),
];

/// EXACT same gradient used by Dashboard's EXPLORE button:
const Gradient kExploreGradient = LinearGradient(
  colors: [
    Color(0xFFFF3D00),
    Color(0xFFFF6D00),
    Color(0xFFFFA726),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

/// ---------------------------
/// COMMUNITY SCREEN (standalone header)
/// ---------------------------
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityUser> users = List.from(_mockUsers);
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<CommunityUser> _filteredUsers() {
    if (_search.trim().isEmpty) return users;
    final q = _search.toLowerCase();
    return users
        .where((u) =>
    u.displayName.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q))
        .toList();
  }

  void _toggleFollow(CommunityUser user) {
    setState(() {
      if (user.isFollowing) {
        // unfollow
        user.isFollowing = false;
        user.requestPending = false;
      } else {
        // follow: if private -> set pending; else follow instantly
        if (user.isPrivate) {
          user.requestPending = true;
        } else {
          user.isFollowing = true;
          user.requestPending = false;
        }
      }
    });
  }

  void _acceptRequest(CommunityUser user) {
    setState(() {
      user.isFollowing = true;
      user.requestPending = false;
    });
  }

  void _openProfile(CommunityUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.78,
        child: ProfilePreview(
          user: user,
          onFollowToggle: () => _toggleFollow(user),
          onAcceptRequest: () => _acceptRequest(user),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'Community',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: _SearchBar(
                  onChanged: (s) => setState(() => _search = s),
                ),
              ),

              // Tabs
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey[600],
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(text: 'Explore'),
                    Tab(text: 'Followers'),
                    Tab(text: 'Following'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Explore
          _buildExplore(filtered),
          // Followers (mock: users who follow you are those with isFollowing true)
          _buildFollowers(),
          // Following (users you follow)
          _buildFollowing(),
        ],
      ),
    );
  }

  Widget _buildExplore(List<CommunityUser> list) {
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final user = list[index];
        return UserCard(
          user: user,
          onTap: () => _openProfile(user),
          onAction: () => _toggleFollow(user),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: list.length,
    );
  }

  Widget _buildFollowers() {
    final followers = users.where((u) => u.isFollowing).toList();
    if (followers.isEmpty) {
      return Center(
        child: Text(
          'No followers yet.\nInvite friends to start.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final user = followers[index];
        return UserCard(
          user: user,
          onTap: () => _openProfile(user),
          onAction: () => _toggleFollow(user),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: followers.length,
    );
  }

  Widget _buildFollowing() {
    final following = users.where((u) => u.isFollowing).toList();
    if (following.isEmpty) {
      return Center(
        child: Text(
          'You are not following anyone yet.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final user = following[index];
        return UserCard(
          user: user,
          onTap: () => _openProfile(user),
          onAction: () => _toggleFollow(user),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: following.length,
    );
  }
}

/// ---------------------------
/// COMMUNITY SCREEN (uses your AppHeader - matches dashboard header)
/// ---------------------------
class CommunityScreenWithAppHeader extends StatefulWidget {
  const CommunityScreenWithAppHeader({super.key});

  @override
  State<CommunityScreenWithAppHeader> createState() =>
      _CommunityScreenWithAppHeaderState();
}

class _CommunityScreenWithAppHeaderState
    extends State<CommunityScreenWithAppHeader> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CommunityUser> users = List.from(_mockUsers);
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  List<CommunityUser> _filteredUsers() {
    if (_search.trim().isEmpty) return users;
    final q = _search.toLowerCase();
    return users
        .where((u) =>
    u.displayName.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q))
        .toList();
  }

  void _toggleFollow(CommunityUser user) {
    setState(() {
      if (user.isFollowing) {
        user.isFollowing = false;
        user.requestPending = false;
      } else {
        if (user.isPrivate) {
          user.requestPending = true;
        } else {
          user.isFollowing = true;
        }
      }
    });
  }

  void _openProfile(CommunityUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.78,
        child: ProfilePreview(
          user: user,
          onFollowToggle: () => _toggleFollow(user),
          onAcceptRequest: () {
            setState(() {
              user.isFollowing = true;
              user.requestPending = false;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers();

    return Scaffold(
      // Use your AppHeader from the dashboard folder so the header matches exactly.
      // If AppHeader requires arguments, adapt this call to pass them.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _SearchBar(onChanged: (s) => setState(() => _search = s)),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: 'Explore'),
                Tab(text: 'Followers'),
                Tab(text: 'Following'),
              ],
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ListView.separated(
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              final user = filtered[index];
              return UserCard(
                user: user,
                onTap: () => _openProfile(user),
                onAction: () => _toggleFollow(user),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: filtered.length,
          ),
          // Followers
          Builder(builder: (context) {
            final followers = users.where((u) => u.isFollowing).toList();
            if (followers.isEmpty) {
              return Center(
                child: Text(
                  'No followers yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final user = followers[index];
                return UserCard(
                  user: user,
                  onTap: () => _openProfile(user),
                  onAction: () => _toggleFollow(user),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: followers.length,
            );
          }),
          // Following
          Builder(builder: (context) {
            final following = users.where((u) => u.isFollowing).toList();
            if (following.isEmpty) {
              return Center(
                child: Text(
                  'You are not following anyone yet.',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final user = following[index];
                return UserCard(
                  user: user,
                  onTap: () => _openProfile(user),
                  onAction: () => _toggleFollow(user),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: following.length,
            );
          }),
        ],
      ),
    );
  }
}

/// ---------------------------
/// SMALL REUSABLE WIDGETS
/// ---------------------------

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search by name or username',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class UserCard extends StatelessWidget {
  final CommunityUser user;
  final VoidCallback onTap;
  final VoidCallback onAction;

  const UserCard({
    required this.user,
    required this.onTap,
    required this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (user.avatarUrl.isEmpty) {
      avatar = CircleAvatar(
        radius: 26,
        backgroundColor: Colors.grey[300],
        child: Text(
          _initials(user.displayName),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      avatar = CircleAvatar(radius: 26, backgroundImage: NetworkImage(user.avatarUrl));
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('@${user.username}', style: TextStyle(color: Colors.grey[600])),
                      if (user.isPrivate) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.lock, size: 14, color: Colors.grey),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            _ActionButton(
              user: user,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  final CommunityUser user;
  final VoidCallback onPressed;
  const _ActionButton({required this.user, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (user.isFollowing) {
      child = const Text('Following', style: TextStyle(color: Colors.white));
    } else if (user.requestPending) {
      child = const Text('Requested', style: TextStyle(color: Colors.white));
    } else {
      child = const Text('Follow', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600));
    }

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: kExploreGradient, // <-- using dashboard explore gradient
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    );
  }
}

/// Profile preview bottom sheet
class ProfilePreview extends StatelessWidget {
  final CommunityUser user;
  final VoidCallback onFollowToggle;
  final VoidCallback onAcceptRequest;

  const ProfilePreview({
    required this.user,
    required this.onFollowToggle,
    required this.onAcceptRequest,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Mock latest activity list:
    final activities = [
      'Completed: Full Body Strength (45 min)',
      'Unlocked: Gold Badge',
      'Joined: 30 Day Step Challenge',
    ];

    return SafeArea(
      child: Material(
        child: Column(
          children: [
            // handle
            Container(
              width: 48,
              height: 6,
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            ListTile(
              leading: user.avatarUrl.isEmpty
                  ? CircleAvatar(
                backgroundColor: Colors.grey[200],
                child: Text(_initials(user.displayName)),
              )
                  : CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl)),
              title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${user.username}'),
              trailing: _ActionButton(user: user, onPressed: onFollowToggle),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                children: [
                  _countTile('Followers', user.isFollowing ? '1.2K' : '24'),
                  const SizedBox(width: 12),
                  _countTile('Following', '180'),
                  const SizedBox(width: 12),
                  _countTile('Badges', '3'),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(activities[index]),
                    subtitle: Text('2 days ago'),
                  );
                },
                separatorBuilder: (_, __) => const Divider(),
                itemCount: activities.length,
              ),
            ),

            // If request pending and you're viewing someone who has requested to follow you,
            // show accept button (this sample doesn't model incoming requests fully).
            if (user.requestPending && !user.isFollowing)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                child: ElevatedButton(
                  onPressed: onAcceptRequest,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Accept Request'),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _countTile(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
