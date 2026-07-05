import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'home_screen.dart';
import 'details.dart';
import '../widgets/animated_start_button.dart';
import '../widgets/animated_page_route.dart';

class LabelingIntroScreen extends StatefulWidget {
  final Exercise exercise;

  const LabelingIntroScreen({super.key, required this.exercise});

  @override
  State<LabelingIntroScreen> createState() => _LabelingIntroScreenState();
}

class _LabelingIntroScreenState extends State<LabelingIntroScreen> {
  // Track which page we're on: 0 = labeling1, 1 = labeling2
  int _currentPage = 0;
  final AudioPlayer _pagesSoundPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _playPagesSound();
  }

  void _playPagesSound() async {
    try {
      await _pagesSoundPlayer.setReleaseMode(ReleaseMode.stop);
      await _pagesSoundPlayer.play(AssetSource('audio/pages_sound.mpeg'));
      debugPrint("Pages sound played");
    } catch (e) {
      debugPrint("Error playing pages sound: $e");
    }
  }

  @override
  void dispose() {
    _pagesSoundPlayer.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    setState(() {
      _currentPage = 1;
    });
  }

  void _goToPreviousPage() {
    setState(() {
      _currentPage = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = _currentPage == 0
        ? "assets/images/labeling1.png"
        : "assets/images/labeling2.png";

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Background Image
          Positioned.fill(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),

          // 2. Dark gradient at the bottom for legibility
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),

          // 3. Back Button (top-left, always visible)
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
                onPressed: () {
                  if (_currentPage == 1) {
                    _goToPreviousPage();
                  } else {
                    Navigator.pop(context, false);
                  }
                },
              ),
            ),
          ),

          // 4. Forward arrow on Page 1 (labeling1) - at the top right
          if (_currentPage == 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: _goToNextPage,
                ),
              ),
            ),

          // 5. Start Button at the bottom right - only on Page 2 (labeling2)
          if (_currentPage == 1)
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
                        page: TaskDetailScreen(
                          exercise: widget.exercise,
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
