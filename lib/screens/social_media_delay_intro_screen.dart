import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/animated_start_button.dart';
import '../widgets/animated_page_route.dart';
import 'pdf_viewer_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class SocialMediaDelayIntroScreen extends StatefulWidget {
  final String pdfPath;
  final String title;
  final int durationMinutes;

  const SocialMediaDelayIntroScreen({
    super.key,
    required this.pdfPath,
    required this.title,
    required this.durationMinutes,
  });

  @override
  State<SocialMediaDelayIntroScreen> createState() =>
      _SocialMediaDelayIntroScreenState();
}

class _SocialMediaDelayIntroScreenState
    extends State<SocialMediaDelayIntroScreen> {
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

    sec1Words = "Target: dLPFC Impulse Override".split(' ');
    sec2Words =
        "When the sudden urge to open a social media app hits, STOP. This is an automatic dopamine loop originating from your primitive brain."
            .split(' ');
    sec3Words = "Instructions:".split(' ');
    sec4Words =
        "Start the ${widget.durationMinutes}-minute delay timer. Do not touch your social media apps. Instead, read the attached high-value article below."
            .split(' ');
    sec5Words = "Why this works:".split(' ');
    sec6Words =
        "By consciously resisting this urge, you are engaging your dLPFC (Dorsolateral Prefrontal Cortex)—the brain's command center for impulse control. Each time you override this primitive signal, you are physically strengthening your dLPFC, turning it into an unbreakable brake system for your impulses. Take control."
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
        style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white));
    idx += sec1Words.length;

    final w2 = _buildAnimatedText(sec2Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec2Words.length;

    final w3 = _buildAnimatedText(sec3Words, idx,
        style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white));
    idx += sec3Words.length;

    final w4 = _buildAnimatedText(sec4Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec4Words.length;

    final w5 = _buildAnimatedText(sec5Words, idx,
        style: GoogleFonts.ebGaramond(fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.white));
    idx += sec5Words.length;

    final w6 = _buildAnimatedText(sec6Words, idx,
        style: const TextStyle(
            fontSize: 14, color: Colors.white70, height: 1.4));
    idx += sec6Words.length;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Bottom area = SafeArea bottom + button height (≈80) + some padding
    final double bottomButtonAreaHeight =
        MediaQuery.of(context).padding.bottom + 110;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/social_media_delay.png',
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

          // 3. Scrollable Text Card — starts from screen mid, ends above button
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

          // 4. Back Button
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

          // 5. Animated Start Button at the bottom right
          Positioned(
            bottom: 20,
            right: 24,
            child: SafeArea(
              top: false,
              child: AnimatedStartButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await Future.delayed(const Duration(milliseconds: 400));
                  final result = await navigator.push(
                    AnimatedPageRoute(
                      page: PdfViewerScreen(
                        pdfPath: widget.pdfPath,
                        title: widget.title,
                        durationMinutes: widget.durationMinutes,
                      ),
                    ),
                  );
                  if (result == true) {
                    navigator.pop(true);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
