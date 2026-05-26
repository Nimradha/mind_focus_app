import 'package:flutter/material.dart';
// Replace 'home_screen.dart' with the actual filename of your home screen
import 'home_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const TaskDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Task Details"),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                exercise.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),

            // Image Section
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                exercise.imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                // Optional: errorBuilder helps if an image path is wrong
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(height: 25),

            _buildInstructionsCard(exercise.instructions, context),
            const SizedBox(height: 25),

            Row(
              children: [
                _buildInfoTile(Icons.timer, "DURATION", exercise.duration),

              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // TODO: Add logic to open the actual game or timer here
                exercise.onStart();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0x880D41A1), // Deep Blue color
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                  "Start ",
                  style: TextStyle(color: Colors.white, fontSize: 18)
              ),
            ),

            const SizedBox(height: 15),

            // Blue Start Button from your screenshot
            ElevatedButton(
              onPressed: () {
                // Future logic: Trigger the specific activity
                Navigator.pop(context, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text(
                  "Mark as Done",
                  style: TextStyle(color: Colors.white, fontSize: 18)
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Instructions Card Widget
  Widget _buildInstructionsCard(String text, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info, color: Colors.green),
              SizedBox(width: 10),
              Text("Instructions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 10),
          Text(text, style: const TextStyle(color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }

  // Info Tiles (Duration & Difficulty)
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}