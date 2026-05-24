import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ImaginationTimerScreen extends StatefulWidget {
  final int completedDaysCount;
  final String instruction;

  const ImaginationTimerScreen({
    super.key,
    required this.completedDaysCount,
    required this.instruction
  });

  @override
  State<ImaginationTimerScreen> createState() => _ImaginationTimerScreenState();
}

class _ImaginationTimerScreenState extends State<ImaginationTimerScreen> {
  int _secondsRemaining = 300; // 5 Minutes
  Timer? _timer;
  final AudioPlayer _player = AudioPlayer();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  void _startSession() async {
    // 1. Start Music
    try {
      await _player.play(
          AssetSource('audio/SlowMorning.mp3')); // Make sure this exists!
      _player.setReleaseMode(ReleaseMode.loop); // Keep it playing
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
    _resumeTimer();
  }

  void _resumeTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _endSession();
      }
    });
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        _resumeTimer(); // Start timer again
        _player.resume(); // Resume music
      } else {
        _timer?.cancel(); // Stop the timer
        _player.pause(); // Pause the music
      }
      _isPaused = !_isPaused;
    });
  }

  void _quitEarly() {
    _timer?.cancel();
    _player.stop();
    Navigator.pop(context, false); // Return 'false' so it doesn't mark as done
  }

  void _endSession() {
    _timer?.cancel();
    _player.stop();
    _showFinishedDialog();
  }

  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background helps focus/imagination
      appBar: AppBar(backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _quitEarly, // Stop everything and go back
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 60),
            const SizedBox(height: 30),
            Text(
              _formatTime(_secondsRemaining),
              style: const TextStyle(fontSize: 70, color: Colors.white, fontWeight: FontWeight.w200),
            ),
            const SizedBox(height: 40),

            // NEW: Control Button
            IconButton(
              iconSize: 64,
              icon: Icon(
                _isPaused ? Icons.play_circle : Icons.pause_circle,
                color: Colors.white,
              ),
              onPressed: _togglePause,
            ),
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Text(
                widget.instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, color: Colors.white70, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Session Complete"),
        content: const Text("Your creative agility is growing!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    ).then((_) => Navigator.pop(context, true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.dispose();
    super.dispose();
  }
}