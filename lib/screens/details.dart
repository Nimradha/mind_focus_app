import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
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

  // Word-by-word instruction animation
  int _visibleWordCount = 0;
  Timer? _wordTimer;

  @override
  void initState() {
    super.initState();
    _startInstructionAnimation();
  }

  /// Animates the instruction text word-by-word with a 150ms stagger
  void _startInstructionAnimation() {
    final wordCount = widget.exercise.instructions.split(' ').length;

    _wordTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_visibleWordCount >= wordCount) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleWordCount++;
      });
    });
  }

  @override
  void dispose() {
    _wordTimer?.cancel();
    super.dispose();
  }

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
        title: Text("Task Details", style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold, fontSize: 24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
              child: Text(
                  widget.exercise.title,
                  style: GoogleFonts.ebGaramond(fontSize: 28, fontWeight: FontWeight.bold)
              ),
            ),

            // Image Section (Full Screen Width)
            Image.asset(
              widget.exercise.imagePath,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              ),
            ),

            const SizedBox(height: 25),

            // Instructions Card (Full Screen Width)
            _buildInstructionsCard(widget.exercise.instructions, context),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
          ],
        ),
      ),
    );
  }

  // Instructions Card Widget — with word-by-word animation
  Widget _buildInstructionsCard(String text, BuildContext context) {
    final words = text.split(' ');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.zero,
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
          Wrap(
            children: [
              for (int i = 0; i < words.length; i++)
                AnimatedOpacity(
                  opacity: i < _visibleWordCount ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedSlide(
                    offset: i < _visibleWordCount
                        ? Offset.zero
                        : const Offset(0, 0.5),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Text(
                        words[i],
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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