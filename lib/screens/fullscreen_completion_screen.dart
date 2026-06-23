import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:ui';
import 'dart:math';

class FullScreenCompletionScreen extends StatefulWidget {
  final String imagePath;
  final String title;

  const FullScreenCompletionScreen({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  State<FullScreenCompletionScreen> createState() => _FullScreenCompletionScreenState();
}

class _FullScreenCompletionScreenState extends State<FullScreenCompletionScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 4));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Stack(
        children: [
          // Glassmorphic Backdrop Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.65),
              ),
            ),
          ),

          // Confetti Layer
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // shoot downwards
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.15,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.yellow,
                Colors.pink,
                Colors.purple,
                Colors.orange,
              ],
            ),
          ),

          // Content Area
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Padding & Title
                Padding(
                  padding: const EdgeInsets.only(top: 30.0, left: 20, right: 20),
                  child: Column(
                    children: [
                      const Text(
                        "GREAT JOB!",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.title} Complete",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Image with Zoom-in Entry Animation
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.7, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale,
                            child: child,
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              widget.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: 280,
                                  color: Colors.grey[900],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_not_supported, size: 60, color: Colors.grey),
                                      SizedBox(height: 10),
                                      Text(
                                        "Could not load completion image",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Action Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 40.0, left: 30, right: 30),
                  child: Container(
                    width: double.infinity,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(29),
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.teal],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(29),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Awesome!",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Close button at top right
          Positioned(
            top: 20,
            right: 20,
            child: SafeArea(
              child: ClipOval(
                child: Material(
                  color: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
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
