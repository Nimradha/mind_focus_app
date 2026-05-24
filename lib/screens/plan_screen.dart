import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf_viewer_screen.dart';

class PlanScreen extends StatefulWidget {
  const PlanScreen({super.key});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  Map<int, bool> _dayTasksDone = {};
  // 1. Add this variable to track the active tab

  List<DateTime> _generateCurrentWeek() {
    DateTime now = DateTime.now();
    // Find Monday of the current week
    // weekday is 1 for Monday, 7 for Sunday.
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _buildPlanBody(),
      ),
    );
  }

  // Add these variables to your _PlanScreenState
  int _dailyMarks = 0;
  bool _showQuiz = false;
  bool _showAmountInput = false;
  int _currentQuizQuestion = 0;

// This calculates which day of the program we are showing based on account creation
  int get programDay {
    final user = FirebaseAuth.instance.currentUser;
    DateTime? creationTime = user?.metadata.creationTime;
    if (creationTime == null) return 1;
    
    DateTime now = DateTime.now();
    DateTime creationDate = DateTime(creationTime.year, creationTime.month, creationTime.day);
    DateTime today = DateTime(now.year, now.month, now.day);
    int daysDiff = today.difference(creationDate).inDays;
    return daysDiff + 1; // 1-indexed (Day 1 = creation day)
  }

  Widget _buildPlanBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCustomHeader(),
          const SizedBox(height: 30),
          _buildCalendarHeader(),
          const SizedBox(height: 20),
          _buildHorizontalCalendar(),
          const SizedBox(height: 30),
          _buildTaskHeader(),
          const SizedBox(height: 15),

          // Dynamic Task Dispatcher
          ..._buildDailyTasks(),
        ],
      ),
    );
  }

  List<Widget> _buildDailyTasks() {
    switch (programDay) {
      case 1: // Day 1
      case 2: // Day 2
        return [const Center(child: Text("No challenges for the first 2 days. Get ready!", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))];
      case 3: // Day 3
        return [_buildArticleTask("15 min social media delay", "Read the given article to improve focus")];
      case 4: // Day 4
        return [_buildSimpleDelayTask("Delay 5 minutes from taking your favorite food item", 2)];
      case 5: // Day 5
        return [
          _buildSimpleDelayTask("Delay 5 minutes from taking your favorite food item", 2, showImage: true),
          const SizedBox(height: 15),
          _buildArticleTask("15 min social media delay", "Read the given article to improve focus"),
        ];
      case 6: // Day 6
        return [_buildSimpleDelayTask("Delay 10 minutes from food & think of benefits", 2)];
      case 7: // Day 7
        return [_buildSavingsTask("Never buy the food that you feel to buy","Enter the amount you saved today")];
      default:
        return [const Center(child: Text("Rest Day - Keep your mindset sharp!", style: TextStyle(color: Colors.grey)))];
    }
  }

  // --- UI Components ---

  Widget _buildCustomHeader() {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE0E7FF),
          backgroundImage: AssetImage('assets/images/plain_logo.png'),
          radius: 30,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("NEWRA", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Elevate your focus", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    String currentMonthYear = DateFormat('MMMM yyyy').format(DateTime.now());

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(currentMonthYear, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Icon(Icons.chevron_left, color: Colors.grey[400]),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalCalendar() {
    List<DateTime> weekDays = _generateCurrentWeek();
    DateTime now = DateTime.now();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: weekDays.map((date) {
        // Check if this date is "Today"
        bool isSelected = date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;

        // logic for "isDone": you can set this based on your task history
        // For now, let's say days before today are marked as "Done"
        bool isDone = date.isBefore(DateTime(now.year, now.month, now.day));

        return _calendarDay(
          DateFormat('E').format(date).toUpperCase(), // e.g., "MON"
          date.day.toString(),                         // e.g., "13"
          isSelected,
          isDone,
        );
      }).toList(),
    );
  }

  Widget _calendarDay(String day, String date, bool isSelected, bool isDone) {
    return Column(
      children: [
        Text(day, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          height: 45, width: 45,
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : (isDone ? Colors.green.withOpacity(0.1) : Colors.transparent),
            shape: BoxShape.circle,
            border: isDone ? null : Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
              : Text(date, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildArticleTask(String title, String sub) {
    return _taskContainer(
      title: title,
      sub: sub,
      icon: Icons.article,
      color: Colors.purple,
      action: ElevatedButton(
        onPressed: () => _openArticleAndQuiz(),
        child: const Text("Start"),
      ),
    );
  }

  Widget _buildSimpleDelayTask(String title, int marks, {bool showImage = false}) {
    bool isChecked = _dayTasksDone[programDay] ?? false; // Sync this with a local variable or DB
    return _taskContainer(
      title: title,
      sub: "Mental Discipline",
      icon: Icons.timer,
      color: Colors.orange,
      action: Checkbox(
        value: isChecked,
        onChanged: (val) {
          if (val == true) {
            setState(() => _dayTasksDone[programDay] = val!);
            _updateMarks(marks);
            if (showImage) _showAchievementImage();
          }
        },
      ),
    );
  }

  Widget _taskContainer({
    required String title,
    required String sub,
    required IconData icon,
    required Color color,
    required Widget action,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          action, // This is where the Checkbox or Button goes
        ],
      ),
    );
  }

  void _showAchievementImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/achievement.png', height: 150), // Ensure this path is correct
            const SizedBox(height: 20),
            const Text("Congratulations!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("You've shown incredible discipline today.",
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Thank you!"),
            )
          ],
        ),
      ),
    );
  }

  void _showSuccessPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildSavingsTask(String title, String sub) {
    final TextEditingController _amountController = TextEditingController();
    return Column(
      children: [
        _taskContainer(
          title: title,
          sub: sub,
          icon: Icons.savings,
          color: Colors.purple,
          action: IconButton(icon: const Icon(Icons.add_circle), onPressed: () {
            setState(() => _showAmountInput = true);
          }),
        ),
        if (_showAmountInput)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: TextField(
              controller: _amountController,
              decoration: InputDecoration(
                hintText: "Enter amount saved today",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => _saveToDatabase(_amountController.text),
                ),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
      ],
    );
  }

  void _updateMarks(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totalMarks': FieldValue.increment(points),
        'lastActiveDate': DateTime.now().toString().split(' ')[0],
      }, SetOptions(merge: true));
    }
  }

  void _saveToDatabase(String amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totalSaved': FieldValue.increment(double.parse(amount)),
      }, SetOptions(merge: true));
      setState(() => _showAmountInput = false);
      _showSuccessPopup("Amount saved successfully!");
    }
  }

  void _openArticleAndQuiz() async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PdfViewerScreen(
          pdfPath: 'assets/docs/article1.pdf',
          title: '15 min social media delay',
        ),
      ),
    );
    if (completed == true) {
      _showSuccessPopup("Article read successfully!");
    }
  }



  Widget _buildTaskHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Today's Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.09), borderRadius: BorderRadius.circular(20)),
          child: const Text("3 left", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTaskTile(String title, String sub, IconData icon, Color color, bool isDone) {
    return Opacity(
      opacity: isDone ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDone ? Border.all(color: Colors.grey.shade200, style: BorderStyle.solid) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                  Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            isDone
                ? const Text("Done", style: TextStyle(color: Colors.grey))
                : ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, elevation: 0, shape: const StadiumBorder()),
              child: const Text("Set Time", style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

}