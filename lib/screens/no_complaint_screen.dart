import 'dart:async';
import 'package:flutter/material.dart';

class NoComplaintScreen extends StatefulWidget {
  const NoComplaintScreen({super.key});

  @override
  State<NoComplaintScreen> createState() => _NoComplaintScreenState();
}

class _NoComplaintScreenState extends State<NoComplaintScreen> {
  int _visibleWordCount = 0;
  Timer? _wordTimer;

  late final List<String> sec1Words;
  late final List<String> sec2Words;
  late final List<String> sec3Words;
  late final List<String> sec4Words;
  late final List<String> sec5Words;
  late final List<String> sec6Words;
  late final int totalWords;

  @override
  void initState() {
    super.initState();

    sec1Words = "Target: Metacognitive Monitoring".split(' ');
    sec2Words = "Complaining is an automatic, low-effort neural response to frustration. Today, you will shut down this automatic output.".split(' ');
    sec3Words = "Instructions:".split(' ');
    sec4Words = "For the next 24 hours, commit to zero spoken complaints. When a frustrating situation arises, observe the urge to complain forming in your mind. Pause. Acknowledge the negative thought, but refuse to vocalize it. Immediately redirect your focus to what you can control or a potential solution.".split(' ');
    sec5Words = "Why this works:".split(' ');
    sec6Words = "This is a continuous background task. It forces your brain to constantly monitor its own thoughts (Metacognition). By intentionally blocking the vocalization of negativity, you rewire your neural pathways from reactive victimhood to proactive resilience and stoicism.".split(' ');

    totalWords = sec1Words.length +
        sec2Words.length +
        sec3Words.length +
        sec4Words.length +
        sec5Words.length +
        sec6Words.length;

    _startTextAnimation();
  }

  void _startTextAnimation() {
    _wordTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (_visibleWordCount >= totalWords) {
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

  Widget _buildAnimatedText(List<String> words, int startIndex, {TextStyle? style}) {
    return Wrap(
      children: [
        for (int i = 0; i < words.length; i++)
          AnimatedOpacity(
            opacity: (startIndex + i) < _visibleWordCount ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: (startIndex + i) < _visibleWordCount
                  ? Offset.zero
                  : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0, bottom: 2.0),
                child: Text(
                  words[i],
                  style: style,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    int idx = 0;

    final w1 = _buildAnimatedText(sec1Words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.purpleAccent));
    idx += sec1Words.length;

    final w2 = _buildAnimatedText(sec2Words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec2Words.length;

    final w3 = _buildAnimatedText(sec3Words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.cyanAccent));
    idx += sec3Words.length;

    final w4 = _buildAnimatedText(sec4Words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec4Words.length;

    final w5 = _buildAnimatedText(sec5Words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent));
    idx += sec5Words.length;

    final w6 = _buildAnimatedText(sec6Words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec6Words.length;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomButtonAreaHeight = MediaQuery.of(context).padding.bottom + 105;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/no_complain.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Bottom-only gradient overlay — keeps top image sharp
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // 3. Scrollable Content Card in the bottom half of the screen
          Positioned(
            top: screenHeight * 0.42, // Starts from the middle of the screen
            bottom: bottomButtonAreaHeight, // Ends just above the bottom button
            left: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      w1,
                      const SizedBox(height: 10),
                      w2,
                      const SizedBox(height: 20),
                      w3,
                      const SizedBox(height: 8),
                      w4,
                      const SizedBox(height: 16),
                      w5,
                      const SizedBox(height: 6),
                      w6,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 15,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ),

          // 5. "Mark as Done" Button at bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Mark as Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
