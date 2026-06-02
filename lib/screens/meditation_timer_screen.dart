import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MeditationTimerScreen extends StatefulWidget {
  final int minutes; // duration in minutes
  const MeditationTimerScreen({super.key, required this.minutes});

  @override
  State<MeditationTimerScreen> createState() => _MeditationTimerScreenState();
}

class _MeditationTimerScreenState extends State<MeditationTimerScreen> {
  late int _secondsRemaining;
  Timer? _timer;
  bool _isPaused = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isMusicPlaying = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.minutes * 60;
    _startAudio();
    _startTimer();
  }

  void _startAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('audio/meditation.mp3'));
      _isMusicPlaying = true;
    } catch (e) {
      debugPrint('Error playing meditation audio: $e');
    }
  }

  void _pauseAudio() async {
    if (_isMusicPlaying) {
      await _audioPlayer.pause();
      _isMusicPlaying = false;
    }
  }

  void _resumeAudio() async {
    if (!_isMusicPlaying) {
      await _audioPlayer.resume();
      _isMusicPlaying = true;
    }
  }

  void _stopAudio() async {
    await _audioPlayer.stop();
    _isMusicPlaying = false;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0 && !_isPaused) {
        setState(() => _secondsRemaining--);
      } else if (_secondsRemaining == 0) {
        _timer?.cancel();
        _stopAudio();
        _showCompletionDialog();
      }
    });
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return "${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Well Done!'),
        content: const Text('Meditation timer completed.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // close dialog
              Navigator.of(context).pop(true); // return to details page
            },
            child: const Text('FINISH'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopAudio();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Meditation Timer'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFE8FAFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              _formatTime(_secondsRemaining),
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w200),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaused ? Colors.green : Colors.orange,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                setState(() => _isPaused = !_isPaused);
                if (_isPaused) {
                  _pauseAudio();
                } else {
                  _resumeAudio();
                }
              },
                  child: Text(_isPaused ? 'RESUME' : 'PAUSE', style: const TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  onPressed: () {
                    _timer?.cancel();
                    _stopAudio();
                    Navigator.of(context).pop(false); // stop -> back to details
                  },
                  child: const Text('STOP', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
