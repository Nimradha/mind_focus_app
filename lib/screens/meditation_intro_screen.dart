import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'details.dart';

class MeditationIntroScreen extends StatefulWidget {
  final Exercise exercise;

  const MeditationIntroScreen({super.key, required this.exercise});

  @override
  State<MeditationIntroScreen> createState() => _MeditationIntroScreenState();
}

class _MeditationIntroScreenState extends State<MeditationIntroScreen> {
  @override
  Widget build(BuildContext context) {
    bool isBefore6PM = DateTime.now().hour < 18;
    String imagePath = isBefore6PM 
        ? "assets/images/med_morning.jpeg" 
        : "assets/images/med_night.jpeg";

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
          
          // 2. Dark/Light gradient at the bottom to ensure button legibility
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

          // 3. Back Button
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

          // 4. Start Button at the bottom (Title & Subtitle removed)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Start Button directs to details page (TaskDetailScreen)
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
                        minimumSize: const Size(100,30),
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
