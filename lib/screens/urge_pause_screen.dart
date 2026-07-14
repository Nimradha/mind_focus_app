import 'dart:async';
import 'package:flutter/material.dart';

class UrgePauseScreen extends StatefulWidget {
  final String title;
  const UrgePauseScreen({super.key, required this.title});

  @override
  State<UrgePauseScreen> createState() => _UrgePauseScreenState();
}

class _UrgePauseScreenState extends State<UrgePauseScreen> {
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

    sec1Words = "Target: Amygdala Deactivation".split(' ');
    sec2Words =
        "Cravings disguise themselves as hunger or the need for entertainment. Usually, they are just stress or boredom in hiding. Unmask them."
            .split(' ');
    sec3Words = "Instructions:".split(' ');
    sec4Words =
        "When a strong urge hits (to scroll, eat junk, or procrastinate), hit the pause timer. Do not just observe the urge—interrogate it. Name it out loud or in your mind: \"I am not hungry; I am just stressed about my module.\" \"I don't need to scroll; I am just bored.\""
            .split(' ');
    sec5Words = "Why this works:".split(' ');
    sec6Words =
        "In neuroscience, this is called \"Affect Labeling.\" The moment you attach a specific word to an emotional urge, you instantly shift blood flow and brain activity away from the emotional center (Amygdala) and into the logical command center (Prefrontal Cortex). Naming the enemy destroys its power over you."
            .split(' ');

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

  Widget _buildAnimatedText(List<String> words, int startIndex,
      {TextStyle? style}) {
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
                child: Text(words[i], style: style),
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
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.orangeAccent));
    idx += sec1Words.length;

    final w2 = _buildAnimatedText(sec2Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec2Words.length;

    final w3 = _buildAnimatedText(sec3Words, idx,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.cyanAccent));
    idx += sec3Words.length;

    final w4 = _buildAnimatedText(sec4Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec4Words.length;

    final w5 = _buildAnimatedText(sec5Words, idx,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.redAccent));
    idx += sec5Words.length;

    final w6 = _buildAnimatedText(sec6Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec6Words.length;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomButtonAreaHeight =
        MediaQuery.of(context).padding.bottom + 105;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/urge_pause.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Bottom-only gradient — keeps top of image sharp
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

          // 3. Scrollable card — starts from screen midpoint, ends above button
          Positioned(
            top: screenHeight * 0.42,
            bottom: bottomButtonAreaHeight,
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

          // 5. "Mark as Done" button at the bottom
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
