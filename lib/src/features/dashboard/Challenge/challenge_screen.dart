// file: lib/src/features/dashboard/Challenge/challenge_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen>
    with SingleTickerProviderStateMixin {
  // Mock challenge data model
  final List<Challenge> _challenges = [
    Challenge(
      id: 'c1',
      title: '10K Steps Daily',
      description: 'Walk 10,000 steps every day.',
      durationDays: 7,
      rewardPoints: 150,
      difficulty: Difficulty.easy,
      iconData: Icons.directions_walk,
    ),
    Challenge(
      id: 'c2',
      title: '30-Day Yoga',
      description: 'Complete daily yoga sessions.',
      durationDays: 30,
      rewardPoints: 400,
      difficulty: Difficulty.moderate,
      iconData: Icons.self_improvement,
    ),
    Challenge(
      id: 'c3',
      title: 'Weekly HIIT Blitz',
      description: 'Finish 3 HIIT workouts this week.',
      durationDays: 7,
      rewardPoints: 200,
      difficulty: Difficulty.hard,
      iconData: Icons.local_fire_department,
    ),
  ];

  // Track joined state & progress locally (mock)
  final Map<String, JoinedChallenge> _joined = {};

  // Animation controller for animated progress changes
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Example: user already joined the second one
    _joined['c2'] =
        JoinedChallenge(challengeId: 'c2', progress: 0.4, status: VerificationStatus.pending);
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Show proof upload bottom sheet
  void _showUploadSheet(Challenge challenge) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // for keyboard if needed
          child: SizedBox(
            height: 300,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Upload your proof', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Please upload an image or short video as proof. Make sure the media was captured today.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: connect camera capture & upload logic
                            Navigator.of(context).pop();
                            _showSnack('Camera picked (mock)');
                          },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Take Photo'),
                          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: gallery pick & upload
                            Navigator.of(context).pop();
                            _showSnack('Gallery picked (mock)');
                          },
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // Toggle join for a challenge
  void _toggleJoin(Challenge c) {
    setState(() {
      if (_joined.containsKey(c.id)) {
        _joined.remove(c.id);
        _showSnack('Left "${c.title}"');
      } else {
        _joined[c.id] =
            JoinedChallenge(challengeId: c.id, progress: 0.0, status: VerificationStatus.notSubmitted);
        _animationController.forward(from: 0);
        _showSnack('Joined "${c.title}"');
      }
    });
  }

  // Mock function to increment progress for joined challenges (for demo)
  void _incrementProgress(String challengeId) {
    setState(() {
      final j = _joined[challengeId];
      if (j == null) return;
      j.progress = (j.progress + 0.15).clamp(0.0, 1.0);
      if (j.progress >= 1.0) {
        j.status = VerificationStatus.submitted;
      }
    });
    _showSnack('Progress updated (mock)');
  }

  // Reusable gradient action button matching Dashboard's Explore button
  Widget _gradientActionButton({
    required String text,
    required VoidCallback onPressed,
    double? width,
    double height = 44,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
  }) {
    final BorderRadius br = borderRadius ?? BorderRadius.circular(12);
    final TextStyle ts = textStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        );

    return Container(
      width: width,
      height: height,
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
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: br,
        child: InkWell(
          borderRadius: br,
          onTap: onPressed,
          child: Center(child: Text(text, style: ts)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We'll use the dashboard header style: curved bottom, shadow, padding
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      // NOTE: removed AppBar. Using header container matching DashboardScreen style
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER (same design as Dashboard screen header but only centered "Challenge")
              Container(
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
                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025, top: 40, bottom: 10),
                child: SizedBox(
                  height: 56,
                  child: Center(
                    child: Text(
                      'Challenge',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              // BODY CONTENT (kept same as previous implementation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFeaturedBanner(width),
                    const SizedBox(height: 20),
                    _sectionTitle('Active Challenges'),
                    const SizedBox(height: 12),
                    Column(
                      children: _challenges.map(_buildChallengeCard).toList(),
                    ),
                    const SizedBox(height: 20),
                    if (_joined.isNotEmpty) ...[
                      _sectionTitle('My Challenges'),
                      const SizedBox(height: 12),
                      Column(
                        children: _joined.values.map(_buildJoinedCard).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    _leaderboardTeaser(),
                    const SizedBox(height: 28),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_joined.isEmpty) {
            _showSnack('Join a challenge to enable quick actions (mock)');
            return;
          }
          final firstId = _joined.keys.first;
          _incrementProgress(firstId);
        },
        label: const Text('Quick'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeaturedBanner(double width) {
    final featured = Challenge(
      id: 'featured',
      title: 'Weekly Fitness Challenge',
      description: 'Complete 5 workouts this week',
      durationDays: 7,
      rewardPoints: 200,
      difficulty: Difficulty.moderate,
      iconData: Icons.emoji_events,
    );

    final bool isJoined = _joined.containsKey(featured.id);

    return GestureDetector(
      onTap: () {
        _showSnack('Open featured details (mock)');
      },
      child: SizedBox(
        height: 180,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: DecorationImage(
                  image: const NetworkImage('https://picsum.photos/800/400'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.25), BlendMode.darken),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.22),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Featured Challenge',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 6),
                            Text('200 pts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const Spacer(),
                  Text(featured.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(featured.description, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  // Use AnimatedCrossFade to avoid layout jumps/overflows when swapping widgets
                  Row(
                    children: [
                      // The action area uses Expanded so it will adapt to available width
                      Expanded(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          child: AnimatedCrossFade(
                            firstChild: SizedBox(
                              height: 44,
                              child: _gradientActionButton(
                                text: 'Join Now',
                                onPressed: () {
                                  setState(() {
                                    _joined[featured.id] = JoinedChallenge(
                                        challengeId: featured.id,
                                        progress: 0.0,
                                        status: VerificationStatus.notSubmitted);
                                  });
                                  _showSnack('Joined featured challenge (mock)');
                                },
                                width: double.infinity,
                                height: 44,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            secondChild: SizedBox(
                              height: 44,
                              child: _AnimatedProgressBar(
                                value: _joined[featured.id]?.progress ?? 0,
                                label: null,
                                height: 44,
                              ),
                            ),
                            crossFadeState:
                            isJoined ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                            firstCurve: Curves.easeOutCubic,
                            secondCurve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 40,
                        child: IconButton(
                          onPressed: () {
                            _showSnack('Featured info (mock)');
                          },
                          icon: const Icon(Icons.info_outline, color: Colors.white),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700));
  }

  Widget _buildChallengeCard(Challenge c) {
    final isJoined = _joined.containsKey(c.id);
    final joined = _joined[c.id];

    // Make right column flexible but constrained so it won't grow beyond available space
    const double rightMaxWidth = 140;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.iconData, size: 32, color: _difficultyColor(c.difficulty)),
              ),
              const SizedBox(width: 12),
              // Middle content is flexible and will wrap text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(c.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text('${c.rewardPoints} pts', style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        Text('${c.durationDays} days', style: const TextStyle(color: Colors.grey)),
                        Chip(
                          backgroundColor: _difficultyColor(c.difficulty).withOpacity(0.12),
                          label: Text(_difficultyText(c.difficulty), style: TextStyle(color: _difficultyColor(c.difficulty))),
                          visualDensity: VisualDensity.compact,
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side uses AnimatedCrossFade + ConstrainedBox to avoid overflow
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: rightMaxWidth, minWidth: 80),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: isJoined
                      ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: _AnimatedProgressBar(
                          value: joined?.progress ?? 0,
                          label: '${((joined?.progress ?? 0) * 100).round()}%',
                          height: 36,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => _showUploadSheet(c),
                          child: const Text('Upload Proof'),
                        ),
                      ),
                    ],
                  )
                      : SizedBox(
                    width: double.infinity,
                    child: _gradientActionButton(
                      text: 'Join',
                      onPressed: () => _toggleJoin(c),
                      height: 40,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedCard(JoinedChallenge joined) {
    final challenge = _challenges.firstWhere((c) => c.id == joined.challengeId,
        orElse: () => Challenge(
          id: joined.challengeId,
          title: 'Featured Challenge',
          description: '',
          durationDays: 7,
          rewardPoints: 0,
          difficulty: Difficulty.easy,
          iconData: Icons.emoji_events,
        ));

    const double actionsWidth = 72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.white),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                child: Icon(challenge.iconData, size: 36, color: _difficultyColor(challenge.difficulty)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(
                        'Progress: ${(joined.progress * challenge.durationDays).round()} / ${challenge.durationDays} days',
                        style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(height: 8),
                    _AnimatedProgressBar(value: joined.progress, label: null, height: 10),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusBadge(joined.status),
                        const SizedBox(width: 8),
                        Text('${challenge.rewardPoints} pts', style: const TextStyle(fontWeight: FontWeight.w700))
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: actionsWidth,
                child: Column(
                  children: [
                    IconButton(
                      onPressed: () {
                        _showUploadSheet(challenge);
                      },
                      icon: const Icon(Icons.upload_file),
                      tooltip: 'Upload proof',
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _joined.remove(joined.challengeId);
                        });
                        _showSnack('Left ${challenge.title} (mock)');
                      },
                      icon: const Icon(Icons.exit_to_app),
                      tooltip: 'Leave challenge',
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(VerificationStatus s) {
    Color bg;
    String text;
    switch (s) {
      case VerificationStatus.pending:
        bg = Colors.orange.withOpacity(0.12);
        text = 'Pending';
        break;
      case VerificationStatus.approved:
        bg = Colors.green.withOpacity(0.12);
        text = 'Approved';
        break;
      case VerificationStatus.rejected:
        bg = Colors.red.withOpacity(0.12);
        text = 'Rejected';
        break;
      case VerificationStatus.submitted:
        bg = Colors.blue.withOpacity(0.12);
        text = 'Submitted';
        break;
      case VerificationStatus.notSubmitted:
      default:
        bg = Colors.grey.withOpacity(0.08);
        text = 'Not submitted';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
    );
  }

  Widget _leaderboardTeaser() {
    final top = [
      const Leader('Rahul', 980),
      const Leader('Ananya', 920),
      const Leader('Arjun', 875),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Leaderboard'),
        const SizedBox(height: 12),
        Material(
          elevation: 1,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Colors.grey[50]),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: top.map((t) {
                      return Expanded(
                        child: Column(
                          children: [
                            CircleAvatar(child: Text(t.name[0]), backgroundColor: Colors.primaries[Random().nextInt(Colors.primaries.length)]),
                            const SizedBox(height: 8),
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('${t.points} pts', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _showSnack('Open full leaderboard (mock)');
                  },
                  child: const Text('View Leaderboard'),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return Colors.green;
      case Difficulty.moderate:
        return Colors.orange;
      case Difficulty.hard:
        return Colors.red;
    }
  }

  String _difficultyText(Difficulty d) {
    switch (d) {
      case Difficulty.easy:
        return 'Easy';
      case Difficulty.moderate:
        return 'Moderate';
      case Difficulty.hard:
        return 'Hard';
    }
  }
}

// Small animated progress bar widget
class _AnimatedProgressBar extends StatefulWidget {
  final double value;
  final String? label;
  final double height;

  const _AnimatedProgressBar({Key? key, required this.value, this.label, this.height = 12}) : super(key: key);

  @override
  State<_AnimatedProgressBar> createState() => _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar> with SingleTickerProviderStateMixin {
  late double _oldValue;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _AnimatedProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _anim = Tween<double>(begin: _oldValue, end: widget.value).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barHeight = widget.height;
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final v = _anim.value.clamp(0.0, 1.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: barHeight,
              decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: v,
                child: Container(
                  decoration: BoxDecoration(
                    color: v > 0.66 ? Colors.green : (v > 0.33 ? Colors.orange : Colors.red),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (widget.label != null) ...[
              const SizedBox(height: 6),
              Text(widget.label!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ]
          ],
        );
      },
    );
  }
}

// Minimal models
class Challenge {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final int rewardPoints;
  final Difficulty difficulty;
  final IconData iconData;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.rewardPoints,
    required this.difficulty,
    required this.iconData,
  });
}

enum Difficulty { easy, moderate, hard }

class JoinedChallenge {
  final String challengeId;
  double progress; // 0.0..1.0
  VerificationStatus status;

  JoinedChallenge({required this.challengeId, required this.progress, required this.status});
}

enum VerificationStatus { notSubmitted, pending, submitted, approved, rejected }

class Leader {
  final String name;
  final int points;
  const Leader(this.name, this.points);
}