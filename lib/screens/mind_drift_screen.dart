import 'dart:async';
import 'package:flutter/material.dart';

class MindDriftScreen extends StatefulWidget {
  const MindDriftScreen({super.key});

  @override
  State<MindDriftScreen> createState() => _MindDriftScreenState();
}

class _MindDriftScreenState extends State<MindDriftScreen> {
  int _visibleWordCount = 0;
  Timer? _wordTimer;

  late final List<String> sec1Words;
  late final List<String> sec2Words;
  late final List<String> sec3Words;
  late final List<String> sec4Words;
  late final int totalWords;

  @override
  void initState() {
    super.initState();

    sec1Words = 'Mind\u2011drift reminder'.split(' ');
    sec2Words =
        'Whenever you notice your thoughts wandering, gently bring attention back to the present moment.'
            .split(' ');
    sec3Words = 'Why this matters:'.split(' ');
    sec4Words =
        'Every time you catch a wandering mind and redirect it, you are strengthening your prefrontal cortex — the part of your brain responsible for focus, discipline, and decision-making. This is a continuous background task. Each redirect is a mental rep. Do it all day.'
            .split(' ');

    totalWords = sec1Words.length +
        sec2Words.length +
        sec3Words.length +
        sec4Words.length;

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

    final wTitle = _buildAnimatedText(sec1Words, idx,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.orangeAccent));
    idx += sec1Words.length;

    final wDesc = _buildAnimatedText(sec2Words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5));
    idx += sec2Words.length;

    final wWhy = _buildAnimatedText(sec3Words, idx,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.cyanAccent));
    idx += sec3Words.length;

    final wWhyDesc = _buildAnimatedText(sec4Words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5));
    idx += sec4Words.length;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomButtonAreaHeight =
        MediaQuery.of(context).padding.bottom + 105;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/day8.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Bottom-only gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.75),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),

          // 3. Scrollable content card (bottom half)
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
                      wTitle,
                      const SizedBox(height: 12),
                      wDesc,
                      const SizedBox(height: 20),
                      wWhy,
                      const SizedBox(height: 8),
                      wWhyDesc,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Floating back button
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
