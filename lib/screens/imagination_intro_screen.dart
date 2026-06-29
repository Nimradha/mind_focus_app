import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'details.dart';

class ImaginationIntroScreen extends StatefulWidget {
  final Exercise exercise;

  const ImaginationIntroScreen({super.key, required this.exercise});

  @override
  State<ImaginationIntroScreen> createState() => _ImaginationIntroScreenState();
}

class _ImaginationIntroScreenState extends State<ImaginationIntroScreen> {
  // Track which page we're on: 0 = imagination1, 1 = imagination2
  int _currentPage = 0;

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
        ? "assets/images/imagination1.png"
        : "assets/images/imagination2.png";

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

          // 4. Forward arrow on Page 1 (imagination1) - at the top right
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

          // 5. Start Button at the bottom - only on Page 2 (imagination2)
          if (_currentPage == 1)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (context) => TaskDetailScreen(
                                exercise: widget.exercise,
                              ),
                            ),
                          );

                          if (result == true) {
                            navigator.pop(true);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(50, 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          "Start",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
