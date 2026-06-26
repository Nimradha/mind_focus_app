import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'meditation_timer_screen.dart';
import 'word_game_screen.dart';
import 'running_timer_screen.dart';
import 'imagination_timer_screen.dart';


class TaskDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const TaskDetailScreen({super.key, required this.exercise});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _taskCompleted = false;

  Future<void> _onStartPressed() async {
    final title = widget.exercise.title.toLowerCase();
    Widget targetScreen;
    if (title.contains('word')) {
      targetScreen = const WordGameScreen(completedDaysCount: 0);
    } else if (title.contains('run')) {
      final minutesMatch = RegExp(r'(\d+)').firstMatch(widget.exercise.duration);
      final minutes = minutesMatch != null ? int.parse(minutesMatch.group(0)!) : 0;
      targetScreen = RunningTimerScreen(
        completedDaysCount: 0,
        minutes: minutes,
        instruction: widget.exercise.instructions,
      );
    } else if (title.contains('somatic') || title.contains('labeling') || title.contains('imagination')) {
      targetScreen = ImaginationTimerScreen(
        completedDaysCount: 0,
        instruction: widget.exercise.instructions,
      );
    } else {
      final minutesMatch = RegExp(r'(\d+)').firstMatch(widget.exercise.duration);
      final minutes = minutesMatch != null ? int.parse(minutesMatch.group(0)!) : 0;
      targetScreen = MeditationTimerScreen(
        minutes: minutes,
      );
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
    if (result == true) {
      // The timer/activity was fully completed — now reveal "Mark as Done"
      setState(() {
        _taskCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Task Details"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                widget.exercise.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),

            // Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                widget.exercise.imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildInstructionsCard(widget.exercise.instructions, context),
            const SizedBox(height: 25),

            Row(
              children: [
                _buildInfoTile(Icons.timer, "DURATION", widget.exercise.duration),
              ],
            ),
            const SizedBox(height: 40),

            // Start button — always visible
            ElevatedButton(
              onPressed: _taskCompleted ? null : _onStartPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _taskCompleted
                    ? Colors.grey.shade400
                    : const Color(0x880D41A1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text(
                  _taskCompleted ? "Completed ✓" : "Start",
                  style: const TextStyle(color: Colors.white, fontSize: 18)
              ),
            ),

            const SizedBox(height: 15),

            // Mark as Done — only appears after the task timer is fully completed
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _taskCompleted
                  ? ElevatedButton(
                      key: const ValueKey('markAsDone'),
                      onPressed: () {
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: const Text(
                          "Mark as Done",
                          style: TextStyle(color: Colors.white, fontSize: 18)
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }

  // Instructions Card Widget
  Widget _buildInstructionsCard(String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.green),
              SizedBox(width: 10),
              Text("Instructions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  // Info Tiles (Duration & Difficulty)
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}