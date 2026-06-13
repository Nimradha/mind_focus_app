import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class AchievementScreen extends StatefulWidget {
  final String message;
  const AchievementScreen({super.key, required this.message});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    _confettiController.play(); // Starts falling immediately
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0), // Creamy background from image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color(0xFF8D5B14),
          onPressed: () {
            // This sends the user back to the Home Screen
            Navigator.pop(context);
          },
        ),
        title: const Text("MindGym", style: TextStyle(color: Color(0xFF8D5B14),fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
        actions: const [Padding(padding: EdgeInsets.all(15))],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // --- Top Circular Badge ---
                _buildMainBadge(),
                const SizedBox(height: 30),
                const Text("Congratulations!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF634205))),
                const SizedBox(height: 10),
                Text(
                  widget.message, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 16, color: Colors.grey)
                ),
                const SizedBox(height: 35),

                // --- Stats Cards Row ---
                Row(
                  children: [
                    _buildStatCard("ACTIVE", "12", "Daily Streak", Icons.local_fire_department, Colors.orange),
                    const SizedBox(width: 15),
                    _buildStatCard("+250", "1,420", "XP Earned", Icons.bolt, Colors.deepOrangeAccent),
                  ],
                ),
                const SizedBox(height: 35),

                const SizedBox(height: 30),
                // --- Buttons ---
                _largeButton("Continue Journey", const Color(0xFF8D5B14), Colors.white,
                      () {
                    // This will now execute when the button is clicked
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                const Text("Now it's time to master your momentum.Plan rest of your day with extra training and plans", style: TextStyle(color: Colors.brown, fontSize: 15),textAlign: TextAlign.center),

              ],
            ),
          ),

          // --- Confetti Layer ---
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.1,
              numberOfParticles: 15,
              gravity: 0.1,
              colors: const [Colors.orange, Colors.yellow, Colors.brown],
            ),
          ),
        ],
      ),
    );
  }

  // --- Widget Helpers ---

  Widget _buildMainBadge() {
    return Container(
      height: 180, width: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFD966).withOpacity(0.3),
      ),
      alignment: Alignment.center,
      child: Container(
        height: 140, width: 140,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD966)),
        child: const Icon(Icons.stars, size: 70, color: Color(0xFF8D5B14)),
      ),
    );
  }

  Widget _buildStatCard(String topText, String mainVal, String subText, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(backgroundColor: iconColor.withOpacity(0.2), child: Icon(icon, color: iconColor, size: 20)),
                Text(topText, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 15),
            Text(mainVal, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(subText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardTile(String title, String progressText, double progress, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: const Color(0xFFF2EBE1), borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          CircleAvatar(radius: 25, backgroundColor: Colors.brown.shade200, child: Icon(icon, color: Colors.white)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: progress, color: const Color(0xFF8D5B14), backgroundColor: Colors.grey.shade300),
                const SizedBox(height: 5),
                Text(progressText, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _largeButton(String text, Color bg, Color txtColor, VoidCallback? onTap) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0),
        onPressed: onTap,
        child: Text(text, style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}