import 'dart:async';
import 'package:flutter/material.dart';

class RunningTimerScreen extends StatefulWidget {
  final int completedDaysCount;
  // New optional parameters to customize timer
  final int? minutes; // duration in minutes (overrides default based on completedDaysCount)
  final String? instruction; // custom instruction text for the exercise

  const RunningTimerScreen({super.key, required this.completedDaysCount, this.minutes, this.instruction});

  @override
  State<RunningTimerScreen> createState() => _RunningTimerScreenState();
}

class _RunningTimerScreenState extends State<RunningTimerScreen> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _isPaused = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    // Use provided minutes if available, otherwise fallback to default logic
    if (widget.minutes != null) {
      _secondsRemaining = widget.minutes! * 60;
    } else {
      // 1st 15 days = 5 mins (300s), next 15 days = 10 mins (600s)
      _secondsRemaining = widget.completedDaysCount < 15 ? 300 : 600;
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && !_isPaused) {
        setState(() => _secondsRemaining--);
      } else if (_secondsRemaining == 0) {
        _timer?.cancel();
        setState(() {
          _isCompleted = true;
        });
        _showCompletionDialog();
      }
    });
  }

  String _getInstruction() {
  // If a custom instruction was passed, use it directly
  if (widget.instruction != null && widget.instruction!.isNotEmpty) {
    return widget.instruction!;
  }
  // Use the same instruction set as defined in HomeScreen
  int day = widget.completedDaysCount + 1;
  // --- 5 MINUTE SESSIONS (Days 1 - 15) ---
  if (day <= 3) return "Start counting from 500.Decrease by exactly 3 at each step.Continue counting down until you reach 0.(500, 497, 494...).Tap the start button below to kick off your daily routine.Let's make progress together, one step at a time. ";
  if (day <= 6) return "Start counting from 500.Decrease by exactly 7 at each step.Continue counting down until you reach 0(500, 493, 486...).Tap the start button below to kick off your daily routine.Let's make progress together, one step at a time. ";
  if (day <= 9) return "Start counting from 500.Decrease by exactly 13 at each step.Continue counting down until you reach 0 (500, 487, 474...).";
  if (day <= 12) return "Start counting from 1000.Decrease by exactly 3 at each step.Continue counting down until you reach 0 (1000, 997, 994...).";
  if (day <= 15) return "Start counting from 1000.Decrease by exactly 7 at each step.Continue counting down until you reach 0 (1000, 993, 986...).";
  if (day <= 18) return "Start counting from 1000.Decrease by exactly 13 at each step.Continue counting down until you reach 0 (1000, 987, 974...).";
  if (day <= 24) return "Start counting from 1000.Decrease from 1 to 5 sequentially (1000, 999, 997, 994,990,985) then repeat decreasing again from 1 to 5 (984,982,979...)";
  if (day <= 30) return "Start counting from 1000.Decrease from 1 to 10 sequentially (1000, 999, 997, 994...) then repeat decreasing again from 1 to 10";
  return "FINAL CHALLENGE: Start counting from any random number.Decrease from 1 to 15 sequentially after every breath.";
}

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _isCompleted);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFF),
        appBar: AppBar(
            title: Text(
              "Running Session",
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
              ),
            ),
            backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFE8FAFF),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/runtimer.jpeg'
                        : 'assets/images/runlight_timer.jpeg',
                    width: 150,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _formatTime(_secondsRemaining),
                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200),
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    backgroundColor: _isPaused ? Colors.green : Colors.orange,
                  ),
                  onPressed: () => setState(() => _isPaused = !_isPaused),
                  child: Text(_isPaused ? "RESUME" : "PAUSE", style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Great Job!"),
        content: const Text("You have completed today's running and mental math exercise."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text("FINISH"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

}