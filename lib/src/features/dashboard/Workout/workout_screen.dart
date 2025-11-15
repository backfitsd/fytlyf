// file: lib/src/features/workouts/view/workout_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';

/// A single-file, self-contained Workout Screen UI that is:
/// - visually modern and mobile-friendly
/// - provides preview, player (timer + rest), pause/resume, next exercise
/// - shows progress, estimated duration, calories, and completion flow
/// - includes RPE + notes modal on completion
///
/// Notes:
/// - This implementation uses only Flutter SDK widgets (no external packages).
/// - Replace the video placeholder with `video_player` or your custom player where indicated.
/// - Hook saving/syncing to Firestore / local DB in the saveResults() method.

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class Exercise {
  final String id;
  final String title;
  final String subtitle; // e.g., "3 x 10 reps"
  final int durationSeconds; // active time for exercise
  final int restSeconds; // rest after exercise
  final int caloriesEst; // rough calories for exercise

  Exercise({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationSeconds,
    required this.restSeconds,
    required this.caloriesEst,
  });
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Mock session data — replace with your domain model
  final List<Exercise> _exercises = [
    Exercise(
      id: 'e1',
      title: 'Jumping Jacks',
      subtitle: '3 x 30s',
      durationSeconds: 30,
      restSeconds: 20,
      caloriesEst: 6,
    ),
    Exercise(
      id: 'e2',
      title: 'Push Ups',
      subtitle: '3 x 10 reps',
      durationSeconds: 45,
      restSeconds: 30,
      caloriesEst: 8,
    ),
    Exercise(
      id: 'e3',
      title: 'Bodyweight Squats',
      subtitle: '3 x 12 reps',
      durationSeconds: 50,
      restSeconds: 30,
      caloriesEst: 10,
    ),
  ];

  int _currentIndex = 0;
  bool _isActivePhase = false; // true: exercise playing; false: resting or preview
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _isPaused = false;
  int _totalCalories = 0;
  bool _isCompleted = false;

  // Track completion per exercise (for UI)
  final Map<String, bool> _completed = {};

  @override
  void initState() {
    super.initState();
    for (var e in _exercises) {
      _completed[e.id] = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startExercise() {
    final ex = _exercises[_currentIndex];
    setState(() {
      _isActivePhase = true;
      _isPaused = false;
      _remainingSeconds = ex.durationSeconds;
    });
    _startTimer();
  }

  void _startRest() {
    final ex = _exercises[_currentIndex];
    setState(() {
      _isActivePhase = false;
      _isPaused = false;
      _remainingSeconds = ex.restSeconds;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) return;
      if (_remainingSeconds <= 0) {
        t.cancel();
        _onPhaseComplete();
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _onPhaseComplete() {
    final ex = _exercises[_currentIndex];
    if (_isActivePhase) {
      // mark exercise complete
      setState(() {
        _completed[ex.id] = true;
        _totalCalories += ex.caloriesEst;
      });
      // start rest (unless last exercise)
      if (_currentIndex < _exercises.length - 1) {
        _startRest();
      } else {
        // workout finished
        setState(() {
          _isCompleted = true;
        });
        _showCompletionDialog();
      }
    } else {
      // rest finished — move to next exercise
      if (_currentIndex < _exercises.length - 1) {
        setState(() {
          _currentIndex += 1;
        });
        _startExercise();
      } else {
        // Should not usually happen because active phase ends workout, but keep safe
        setState(() {
          _isCompleted = true;
        });
        _showCompletionDialog();
      }
    }
  }

  void _pauseOrResume() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _skipToNext() {
    _timer?.cancel();
    if (_currentIndex < _exercises.length - 1) {
      setState(() {
        _currentIndex += 1;
        _isActivePhase = false;
      });
    } else {
      setState(() {
        _isCompleted = true;
      });
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() async {
    // Pause any timers
    _timer?.cancel();

    final result = await showDialog<_CompletionResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _CompletionDialog(),
    );

    // Save results and close or update UI
    if (result != null) {
      // TODO: send `result` + session metadata to backend or local DB
      await _saveResults(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout saved locally (mock).')),
        );
      }
    }
  }

  Future<void> _saveResults(_CompletionResult result) async {
    // Replace with Firestore / cloud function call
    await Future.delayed(const Duration(milliseconds: 300));
    // Example payload:
    final payload = {
      'completedAt': DateTime.now().toIso8601String(),
      'exercises': _exercises.map((e) => e.title).toList(),
      'totalCalories': _totalCalories,
      'rpe': result.rpe,
      'notes': result.notes,
    };
    // print(payload); // for debug
  }

  int get _totalDurationSeconds {
    int s = 0;
    for (var e in _exercises) {
      s += e.durationSeconds + e.restSeconds;
    }
    return s;
  }

  int get _elapsedSeconds {
    int elapsed = 0;
    for (int i = 0; i < _currentIndex; i++) {
      final e = _exercises[i];
      elapsed += e.durationSeconds + e.restSeconds;
    }
    final current = _exercises[_currentIndex];
    if (_isActivePhase) {
      elapsed += (current.durationSeconds - _remainingSeconds);
    } else {
      // if resting, add full active time plus elapsed rest
      elapsed += current.durationSeconds + (current.restSeconds - _remainingSeconds);
    }
    return elapsed;
  }

  String _formatTime(int secs) {
    final mm = (secs ~/ 60).toString().padLeft(2, '0');
    final ss = (secs % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final ex = _exercises[_currentIndex];
    final progress = (_elapsedSeconds / _totalDurationSeconds).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top summary card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _TopSummaryCard(
                totalExercises: _exercises.length,
                estimatedDuration: _formatTime(_totalDurationSeconds),
                estimatedCalories: _exercises.fold<int>(0, (p, e) => p + e.caloriesEst),
                completedCount: _completed.values.where((v) => v).length,
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(value: progress, minHeight: 8),
            ),

            const SizedBox(height: 12),

            // Exercise preview & player area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // title + subtitle
                    Text(
                      ex.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ex.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                        Text('${ex.caloriesEst} kcal', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Media placeholder — replace with video player
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            // Replace with video_player widget (VideoPlayer) wrapped by AspectRatio
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.play_circle_outline, size: 72),
                                  SizedBox(height: 8),
                                  Text('Demo video placeholder'),
                                ],
                              ),
                            ),

                            // Small overlay: Active / Rest badge
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Chip(
                                label: Text(_isActivePhase ? 'Active' : 'Rest'),
                              ),
                            ),

                            // Timer overlay bottom-right
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _remainingSeconds > 0 ? _formatTime(_remainingSeconds) : '--:--',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Controls
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isCompleted
                                ? null
                                : (_timer == null ? _startExercise : (_isPaused ? _pauseOrResume : _pauseOrResume)),
                            icon: Icon(_timer == null ? Icons.play_arrow : (_isPaused ? Icons.play_arrow : Icons.pause)),
                            label: Text(_timer == null ? 'Start' : (_isPaused ? 'Resume' : 'Pause')),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: _isCompleted ? null : _skipToNext,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Skip'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Exercise list (compact)
                    SizedBox(
                      height: 88,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _exercises.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final item = _exercises[idx];
                          final done = _completed[item.id] ?? false;
                          final active = idx == _currentIndex;
                          return _MiniExerciseCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            active: active,
                            done: done,
                            onTap: () {
                              _timer?.cancel();
                              setState(() {
                                _currentIndex = idx;
                                _isActivePhase = false;
                                _remainingSeconds = 0;
                                _timer = null;
                                _isPaused = false;
                              });
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // Bottom quick stats
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_completed.values.where((v) => v).length}/${_exercises.length} done', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('Calories: $_totalCalories kcal', style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),

                  ElevatedButton(
                    onPressed: _isCompleted ? null : () {
                      // Quick end — mark all done and open completion
                      _timer?.cancel();
                      for (var e in _exercises) {
                        _completed[e.id] = true;
                      }
                      setState(() {
                        _isCompleted = true;
                      });
                      _showCompletionDialog();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Text('Finish'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _TopSummaryCard extends StatelessWidget {
  final int totalExercises;
  final String estimatedDuration;
  final int estimatedCalories;
  final int completedCount;

  const _TopSummaryCard({
    required this.totalExercises,
    required this.estimatedDuration,
    required this.estimatedCalories,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(
        children: [
          // small circular progress showing exercises
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  value: totalExercises == 0 ? 0 : (completedCount / totalExercises),
                  strokeWidth: 6,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$completedCount', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('/$totalExercises', style: const TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Todays session', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 6),
                    Text(estimatedDuration),
                    const SizedBox(width: 12),
                    const Icon(Icons.local_fire_department, size: 16),
                    const SizedBox(width: 6),
                    Text('$estimatedCalories kcal'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {
              // TODO: preview full plan or regenerate
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    );
  }
}

class _MiniExerciseCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _MiniExerciseCard({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active ? Colors.red.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? Colors.red : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: done ? Colors.green.shade100 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(done ? Icons.check : Icons.fitness_center),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// Completion dialog collects RPE and notes
class _CompletionDialog extends StatefulWidget {
  const _CompletionDialog({super.key});

  @override
  State<_CompletionDialog> createState() => _CompletionDialogState();
}

class _CompletionDialogState extends State<_CompletionDialog> {
  int _rpe = 7;
  final TextEditingController _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rate perceived exertion (RPE)'),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (i) {
                final v = i + 1;
                final selected = v == _rpe;
                return GestureDetector(
                  onTap: () => setState(() => _rpe = v),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? Colors.red : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$v', style: TextStyle(color: selected ? Colors.white : Colors.black)),
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            const Text('Notes (optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'How did it feel? Any adjustments or injuries?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_CompletionResult(rpe: _rpe, notes: _notes.text));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _CompletionResult {
  final int rpe;
  final String notes;

  _CompletionResult({required this.rpe, required this.notes});
}
