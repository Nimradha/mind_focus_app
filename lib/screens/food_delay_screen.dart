import 'dart:async';
import 'package:flutter/material.dart';

class FoodDelayScreen extends StatefulWidget {
  final int durationMinutes;

  const FoodDelayScreen({
    super.key,
    required this.durationMinutes,
  });

  @override
  State<FoodDelayScreen> createState() => _FoodDelayScreenState();
}

class _FoodDelayScreenState extends State<FoodDelayScreen> {
  int _visibleWordCount = 0;
  Timer? _wordTimer;

  late final List<String> sec1_words;
  late final List<String> sec2_words;
  late final List<String> sec3_words;
  late final List<String> sec4_words;
  late final List<String> sec5_words;
  late final List<String> sec6_words;
  late final List<String> sec7_words;
  late final List<String> sec8_words;
  late final List<String> sec9_words;
  late final List<String> sec10_words;
  late final List<String> sec11_words;

  late final int totalWords;

  @override
  void initState() {
    super.initState();

    sec1_words = "Target: Dopamine Loop Inhibition".split(' ');
    sec2_words = "The urge to instantly consume high-dopamine food is a primal reflex. By actively delaying this urge, you train your brain to separate the stimulus from the action.".split(' ');
    sec3_words = "Instructions:".split(' ');
    sec4_words = "OPTION A: The External Test (Priority)".split(' ');
    sec5_words = "When you are outside and get a sudden craving to buy a specific snack or meal, STOP. Start the ${widget.durationMinutes}-minute timer before you make the purchase.".split(' ');
    sec6_words = "OPTION B: The Home Test (Alternative)".split(' ');
    sec7_words = "If you are at home, place your prepared meal exactly in front of you. Start the ${widget.durationMinutes}-minute timer before taking the first bite.".split(' ');
    sec8_words = "During the Timer:".split(' ');
    sec9_words = "Do not eat. Do not buy. Observe your physical hunger and the mental impatience purely as physical data. Do not react.".split(' ');
    sec10_words = "Why this works:".split(' ');
    sec11_words = "Eating is a powerful survival loop. By intentionally delaying consumption when the stimulus is highest, you force your Prefrontal Cortex to suppress the basal ganglia (your primitive brain). This drill builds elite self-mastery.".split(' ');

    totalWords = sec1_words.length +
        sec2_words.length +
        sec3_words.length +
        sec4_words.length +
        sec5_words.length +
        sec6_words.length +
        sec7_words.length +
        sec8_words.length +
        sec9_words.length +
        sec10_words.length +
        sec11_words.length;

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

    final w1 = _buildAnimatedText(sec1_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.greenAccent));
    idx += sec1_words.length;

    final w2 = _buildAnimatedText(sec2_words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec2_words.length;

    final w3 = _buildAnimatedText(sec3_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.cyanAccent));
    idx += sec3_words.length;

    final w4 = _buildAnimatedText(sec4_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent));
    idx += sec4_words.length;

    final w5 = _buildAnimatedText(sec5_words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec5_words.length;

    final w6 = _buildAnimatedText(sec6_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent));
    idx += sec6_words.length;

    final w7 = _buildAnimatedText(sec7_words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec7_words.length;

    final w8 = _buildAnimatedText(sec8_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.redAccent));
    idx += sec8_words.length;

    final w9 = _buildAnimatedText(sec9_words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec9_words.length;

    final w10 = _buildAnimatedText(sec10_words, idx,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.cyanAccent));
    idx += sec10_words.length;

    final w11 = _buildAnimatedText(sec11_words, idx,
        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec11_words.length;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double bottomButtonAreaHeight = MediaQuery.of(context).padding.bottom + 105;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/food_delay.png',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
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
                      const SizedBox(height: 24),
                      w3,
                      const SizedBox(height: 12),
                      w4,
                      const SizedBox(height: 6),
                      w5,
                      const SizedBox(height: 16),
                      w6,
                      const SizedBox(height: 6),
                      w7,
                      const SizedBox(height: 16),
                      w8,
                      const SizedBox(height: 6),
                      w9,
                      const SizedBox(height: 16),
                      w10,
                      const SizedBox(height: 6),
                      w11,
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
