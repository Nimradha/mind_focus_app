import 'package:flutter/material.dart';
import '../widgets/animated_start_button.dart';
import '../widgets/animated_page_route.dart';
import 'pdf_viewer_screen.dart';

class SocialMediaDelayIntroScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          
          // 2. Dark gradient at the bottom to ensure button legibility
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

          // 4. Start Button at the bottom right
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
                        pdfPath: pdfPath,
                        title: title,
                        durationMinutes: durationMinutes,
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
