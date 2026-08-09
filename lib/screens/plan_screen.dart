import 'dart:async';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pdf_viewer_screen.dart';
import 'social_media_delay_intro_screen.dart';
import 'food_delay_screen.dart';
import 'no_complaint_screen.dart';
import 'meditation_focus_screen.dart';
import 'morning_phone_ban_screen.dart';
import 'no_scroll_food_screen.dart';
import 'no_external_food_screen.dart';
import 'no_scroll_screen.dart';
import 'food_delay_evaluate_screen.dart';
import 'urge_pause_screen.dart';
import 'build_savings_screen.dart';
import 'mind_drift_screen.dart';

class PlanScreen extends StatefulWidget {
  final bool isVisible;
  const PlanScreen({super.key, this.isVisible = false});

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late TextEditingController _amountController;
  int _visibleSavingsWordCount = 0;
  Timer? _savingsWordTimer;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _loadChallengeState();
    if (widget.isVisible) {
      _startSavingsHeadingAnimation();
    }
  }

  @override
  void didUpdateWidget(covariant PlanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _savingsWordTimer?.cancel();
      setState(() {
        _visibleSavingsWordCount = 0;
      });
      _startSavingsHeadingAnimation();
    }
  }

  void _startSavingsHeadingAnimation() {
    const heading = "Let's start saving";
    final wordCount = heading.split(' ').length;

    _savingsWordTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_visibleSavingsWordCount >= wordCount) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          _visibleSavingsWordCount++;
        });
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _savingsWordTimer?.cancel();
    super.dispose();
  }
  Map<int, bool> _dayTasksDone = {};
  Map<String, bool> _challengeChecked = {};

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

          if (programDay >= 8) ...[
            const SizedBox(height: 30),
            Wrap(
              children: [
                for (int i = 0; i < "Let's start saving".split(' ').length; i++)
                  AnimatedOpacity(
                    opacity: i < _visibleSavingsWordCount ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: AnimatedSlide(
                      offset: i < _visibleSavingsWordCount
                          ? Offset.zero
                          : const Offset(0, 0.5),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: Text(
                          "Let's start saving".split(' ')[i],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              "Enter the amount you saved today",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 15),
            _buildDailySavingsInput(),
          ],
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
          return [
            _buildSimpleDelayTask("Delay 5 minutes from taking your favorite food item", 2),
            _buildNoScrollFoodTask(),
          ];
        case 5: // Day 5
          return [
            _buildSimpleDelayTask("Delay 5 minutes from taking your favorite food item", 2),
            const SizedBox(height: 15),
            _buildArticleTask("10 min social media delay", "Read the given article to improve focus"),
          ];
        case 6: // Day 6
          return [
            _buildSimpleDelayTask("Delay 10 minutes from taking your favorite food item", 2),
            _buildNoComplaintTask(),
          ];
        case 7: // Day 7
          return [_buildSavingsTask("Never buy the food that you feel to buy","Enter the amount you saved today")];
          case 8: // Day 8
            return [
              _buildMeditationTask("10 min meditation – focus on breathing", "Sit comfortably, close your eyes, and follow the breath."),
              Divider(
                 height: 1,
                 thickness: 1,
                 color: Colors.grey.shade300,
               ),
               const Padding(
                 padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                 child: Align(
                   alignment: Alignment.centerLeft,
                   child: Text(
                     "To be continued throughout the day",
                     style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                   ),
                 ),
               ),
               _buildMindDriftTask(),
            ];
          case 9: // Day 9 
            return [_buildArticleTask("30 min social media delay", "Read the given article to improve focus")];
          case 10: // Day 10 
            return [
              _buildSimpleDelayTask("Delay 10 minutes from taking your favorite food item", 2),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "To be continued throughout the day",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            _buildNoSocialScrollTask(),
            ];
          case 11: // Day 11 
            return [
              _buildMeditationTask("10 min meditation – focus on breathing", "Sit comfortably, close your eyes, and follow the breath."),
            ];
          case 12: // Day 12
            return [
              _buildSimpleDelayTask("20 min food delay – Evaluate the cost and health value of reducing food consumption", 2),
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey.shade300,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "To be continued throughout the day",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
_buildNoExternalFoodTask(),
            ];
          case 13: // Day 13
            return [
              _buildArticleTask("15 min social media delay", "Read the given article to improve focus"),
              const SizedBox(height: 15),
              _buildNoComplaintTask(),
            ];
          case 14: // Day 14
              return [
                _buildSuddenUrgePauseTask(),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                // Second reminder with bracket note
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.withOpacity(0.2),
                        child: Icon(Icons.notifications, color: Colors.orange, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "3‑minute pause",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Text(
                              "Whenever you feel something that distracts your feelings, pause 3 min before acting.",
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ];
            case 15: // Day 15
              return [
                _buildMeditationTask("10 min meditation", "Sit comfortably, close your eyes, and follow the breath."),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                _buildNoSocialScrollTask(),
              ];
            case 16: // Day 16
              return [
                _buildSimpleDelayTask("30 min food delay – Evaluate the cost and health value of reducing food consumption", 2),
              ];
  case 17: // Day 17
              return [
                _buildArticleTask("30 min social media delay", "Read the given article to improve focus"),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                                _buildNoExternalFoodTask(),
              ];
            case 18: // Day 18
              return [
                _buildMeditationTask("10 min meditation", "Sit comfortably, close your eyes, and follow the breath."),
              ];
            case 19: // Day 19
              return [
                _buildSimpleDelayTask("Morning phone ban - no phone for 1st 30 min after waking", 2),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                _buildReminderTask("Call out cravings", "When a craving hits you, call it out by its real name – either say it out louder or write it down on a piece of paper."),
              ];
            case 20: // Day 20
              return [
                _buildReminderTask("3‑minute pause","Whenever you feel something that distracts your feelings - name it, pause 3 min before acting."),
                const SizedBox(height: 15),
                _buildNoComplaintTask(),
              ];
            case 21: // Day 21
              return [
                _buildArticleTask("30 min social media delay", "Read the given article to improve focus"),
              ];
            case 22: // Day 22
              return [
                _buildMeditationTask("15 min meditation", "Sit comfortably, close your eyes, and follow the breath."),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                _buildNoSocialScrollTask(),
              ];
            case 23: // Day 23
              return [
                _buildSimpleDelayTask("Morning phone ban - no phone for 1 hour after waking", 2),
              ];
            case 24: // Day 24
              return [
                _buildSimpleDelayTask("30 min food delay – Evaluate identity : does this serve who I want to become?", 2),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                                _buildNoExternalFoodTask(),
              ];
            case 25: // Day 25
              return [
                _buildMeditationTask("15 min meditation", "Sit comfortably, close your eyes, and follow the breath."),
              ];
            case 26: // Day 26
              return [
                _buildReminderTask("Call out cravings", "When a craving hits you, call it out by its real name – either say it out louder or write it down on a piece of paper."),
              ];
            case 27: // Day 27
              return [
                _buildReminderTask("Identify your hardest distraction", "Pick the one distraction that is hardest for you to resist today, and make a rule that you must wait before giving in to it."),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                _taskContainer(
  title: "Decide your wait time",
  sub: "You get to decide the rules today. Pick the exact number of minutes you will force yourself to wait the next time you feel a sudden urge to distract yourself.",
  icon: Icons.notifications,
  color: Colors.orange,
  action: const SizedBox.shrink(),
),
              ];
            case 28: // Day 28
              return [
                _buildMeditationTask("15 min meditation", "Sit comfortably, close your eyes, and follow the breath."),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10.0, bottom: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "To be continued throughout the day",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                _taskContainer(
                  title: "Be your own coach",
                  sub: "Spot your biggest personal weakness from the past few weeks, and design a custom challenge today to fix that specific problem.",
                  icon: Icons.notifications,
                  color: Colors.orange,
                  action: const SizedBox.shrink(),
                ),
              ];
            case 29: // Day 29
              return [
                _taskContainer(
                  title: "Attention audit",
                  sub: "Once an hour, write down your exact thought. At the end of the day, check if your mind spent its time on things you chose, or if it just reacted to whatever popped up in front of you.",
                  icon: Icons.notifications,
                  color: Colors.orange,
                  action: const SizedBox.shrink(),
                ),
              ];
            case 30: // Day 30
              return [
                _taskContainer(
                  title: "Month reflection",
                  sub: "Think answers for the following questions. What changed? What didn't? What surprised me? What do I continue? Who am I vs day 1?",
                  icon: Icons.notes,
                  color: Colors.blue,
                  action: const SizedBox.shrink(),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: Colors.grey.shade300,
                ),
                _taskContainer(
                  title: "Full dopamine audit",
                  sub: "List top 5 dopamine sources.",
                  icon: Icons.bolt,
                  color: Colors.purple,
                  action: const SizedBox.shrink(),
                ),
              ];
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
            Text(
              "NEWRA",
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
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

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildArticleTask(String title, String sub) {
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;
    return _taskContainer(
      title: title,
      sub: sub,
      icon: Icons.article,
      color: Colors.purple,
      action: isChecked
          ? _buildBadge("DONE", Colors.green.shade100, Colors.green)
          : ElevatedButton(
              onPressed: () => _startArticleChallenge(title, sub),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                elevation: 0,
                shape: const StadiumBorder(),
                side: BorderSide(color: Colors.green.shade100),
              ),
              child: Text(
                "Start",
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.shade800
                      : Colors.green,
                ),
              ),
            ),
    );
  }

  Widget _buildSimpleDelayTask(String title, int marks) {
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;
    final bool useFoodDelayScreen = (programDay == 4 || programDay == 5 || programDay == 6 || programDay == 10);
    final bool useMorningPhoneBanScreen = (programDay == 19 || programDay == 23);
    final bool useFoodDelayEvaluateScreen = (programDay == 12 || programDay == 16 || programDay == 24);

    if (useFoodDelayScreen) {
      return GestureDetector(
        onTap: isChecked
            ? null
            : () => _startSimpleDelayChallenge(title, marks),
        child: _taskContainer(
          title: title,
          sub: "Mental Discipline",
          icon: Icons.timer,
          color: Colors.orange,
          action: IgnorePointer(
            ignoring: !isChecked,
            child: Checkbox(
              value: isChecked,
              onChanged: (val) {
                if (val == false) {
                  setState(() {
                    _challengeChecked['${programDay}_$title'] = false;
                  });
                  _saveChallengeState('${programDay}_$title', false);
                  _updateMarks(-marks);
                }
              },
            ),
          ),
        ),
      );
    } else if (useMorningPhoneBanScreen) {
      return GestureDetector(
        onTap: isChecked
            ? null
            : () => _startMorningPhoneBanChallenge(title, marks),
        child: _taskContainer(
          title: title,
          sub: "Mental Discipline",
          icon: Icons.phone_disabled,
          color: Colors.indigo,
          action: IgnorePointer(
            ignoring: !isChecked,
            child: Checkbox(
              value: isChecked,
              onChanged: (val) {
                if (val == false) {
                  setState(() {
                    _challengeChecked['${programDay}_$title'] = false;
                  });
                  _saveChallengeState('${programDay}_$title', false);
                  _updateMarks(-marks);
                }
              },
            ),
          ),
        ),
      );
    } else if (useFoodDelayEvaluateScreen) {
      return GestureDetector(
        onTap: isChecked
            ? null
            : () => _startFoodDelayEvaluateChallenge(title, marks),
        child: _taskContainer(
          title: title,
          sub: "Mental Discipline",
          icon: Icons.timer,
          color: Colors.orange,
          action: IgnorePointer(
            ignoring: !isChecked,
            child: Checkbox(
              value: isChecked,
              onChanged: (val) {
                if (val == false) {
                  setState(() {
                    _challengeChecked['${programDay}_$title'] = false;
                  });
                  _saveChallengeState('${programDay}_$title', false);
                  _updateMarks(-marks);
                }
              },
            ),
          ),
        ),
      );
    } else {
      return _taskContainer(
        title: title,
        sub: "Mental Discipline",
        icon: Icons.timer,
        color: Colors.orange,
        action: Checkbox(
          value: isChecked,
          onChanged: (val) {
            setState(() {
              _challengeChecked['${programDay}_$title'] = val ?? false;
            });
            _saveChallengeState('${programDay}_$title', val ?? false);
            _updateMarks(val == true ? marks : -marks);
          },
        ),
      );
    }
  }

  Widget _buildNoComplaintTask() {
    final String title = "No complaint day";
    final int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked
          ? null
          : () => _startNoComplaintChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: "Catch every complaint, reframe as neural observation",
        icon: Icons.self_improvement,
        color: Colors.purple,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startNoComplaintChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoComplaintScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  Widget _buildNoScrollFoodTask() {
    const String title = "No-scroll during meals";
    const int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked ? null : () => _startNoScrollFoodChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: "Place phone down at every meal",
        icon: Icons.no_meals,
        color: Colors.teal,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startNoScrollFoodChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoScrollFoodScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  Widget _buildNoExternalFoodTask() {
    const String title = "No external food day";
    const int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked ? null : () => _startNoExternalFoodChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: "Consume only food you already have at home",
        icon: Icons.no_food,
        color: Colors.green,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startNoExternalFoodChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoExternalFoodScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  Widget _buildSuddenUrgePauseTask() {
    const String title = "Sudden urge pause";
    const int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked ? null : () => _startUrgePauseChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: "Whenever you feel a sudden urge that distracts your feelings, just stop and pause it before you actually do it.",
        icon: Icons.notifications,
        color: Colors.orange,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startUrgePauseChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UrgePauseScreen(title: title),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  Widget _buildNoSocialScrollTask() {
    const String title = "No social media scrolling at all";
    const int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked ? null : () => _startNoSocialScrollChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: "Zero doomscrolling today",
        icon: Icons.block,
        color: Colors.deepPurple,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startNoSocialScrollChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoScrollScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
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
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;
    return GestureDetector(
      onTap: isChecked ? null : () => _startSavingsChallenge(title),
      child: _taskContainer(
        title: title,
        sub: sub,
        icon: Icons.savings,
        color: Colors.purple,
        action: isChecked
            ? _buildBadge("DONE", Colors.green.shade100, Colors.green)
            : ElevatedButton(
                onPressed: () => _startSavingsChallenge(title),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: Colors.green.shade100),
                ),
                child: Text(
                  "Start",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade800
                        : Colors.green,
                  ),
                ),
              ),
      ),
    );
  }

  void _startSavingsChallenge(String title) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BuildSavingsScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(2);
    }
  }

    // Meditation task widget
  Widget _buildMeditationTask(String title, String sub) {
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;
    final int marks = 2;

    return GestureDetector(
      onTap: isChecked
          ? null
          : () => _startMeditationChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: sub,
        icon: Icons.self_improvement,
        color: Colors.indigo,
        action: IgnorePointer(
          ignoring: !isChecked,
          child: Checkbox(
            value: isChecked,
            onChanged: (val) {
              if (val == false) {
                setState(() {
                  _challengeChecked['${programDay}_$title'] = false;
                });
                _saveChallengeState('${programDay}_$title', false);
                _updateMarks(-marks);
              }
            },
          ),
        ),
      ),
    );
  }

  void _startMeditationChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeditationFocusScreen(title: title),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  // Mind-drift reminder task widget
  Widget _buildMindDriftTask() {
    const String title = 'Mind\u2011drift reminder';
    const int marks = 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;

    return GestureDetector(
      onTap: isChecked ? null : () => _startMindDriftChallenge(title, marks),
      child: _taskContainer(
        title: title,
        sub: 'Whenever you notice thoughts wandering, gently bring attention back to the present moment.',
        icon: Icons.notifications,
        color: Colors.orange,
        action: isChecked
            ? _buildBadge('DONE', Colors.green.shade100, Colors.green)
            : ElevatedButton(
                onPressed: () => _startMindDriftChallenge(title, marks),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.white,
                  elevation: 0,
                  shape: const StadiumBorder(),
                  side: BorderSide(color: Colors.green.shade100),
                ),
                child: Text(
                  'Start',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.green.shade800
                        : Colors.green,
                  ),
                ),
              ),
      ),
    );
  }

  void _startMindDriftChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MindDriftScreen(),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }


  Widget _buildReminderTask(String title, String sub, {bool showBracket = false}) {
    int marks = showBracket ? 3 : 2;
    bool isChecked = _challengeChecked['${programDay}_$title'] ?? false;
    final bool useUrgePauseScreen = (programDay == 19 || programDay == 26);

    Widget taskWidget = _taskContainer(
      title: title,
      sub: sub,
      icon: Icons.notifications,
      color: Colors.orange,
      action: useUrgePauseScreen
          ? IgnorePointer(
              ignoring: !isChecked,
              child: Checkbox(
                value: isChecked,
                onChanged: (val) {
                  if (val == false) {
                    setState(() {
                      _challengeChecked['${programDay}_$title'] = false;
                    });
                    _saveChallengeState('${programDay}_$title', false);
                    _updateMarks(-marks);
                  }
                },
              ),
            )
          : Checkbox(
              value: isChecked,
              onChanged: (val) {
                if (val == true) {
                  setState(() => _challengeChecked['${programDay}_$title'] = val!);
                  _saveChallengeState('${programDay}_$title', val!);
                  _updateMarks(marks);
                }
              },
            ),
    );

    if (useUrgePauseScreen) {
      taskWidget = GestureDetector(
        onTap: isChecked ? null : () => _startUrgePauseChallenge(title, marks),
        child: taskWidget,
      );
    }

    return Column(
      children: [
        taskWidget,
        if (showBracket) ...[
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(color: Colors.grey, fontSize: 12),
              children: [
                TextSpan(text: 'continue this throughout the day', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
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

  Future<void> _loadChallengeState() async {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now().toString().split(' ')[0];
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['lastActiveDate'] == today && data.containsKey('challengeStates')) {
          final Map<String, dynamic> saved = Map<String, dynamic>.from(data['challengeStates']);
          setState(() {
            _challengeChecked = saved.map((k, v) => MapEntry(k, v as bool));
          });
        } else {
          setState(() => _challengeChecked = {});
        }
      }
    }
  }

  Future<void> _saveChallengeState(String key, bool value) async {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now().toString().split(' ')[0];
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'challengeStates': {key: value},
        'lastActiveDate': today,
      }, SetOptions(merge: true));
    }
  }

  void _saveToDatabase(String amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Validate that the amount is a valid number
      final parsed = double.tryParse(amount.trim());
      if (parsed == null) {
        _showSuccessPopup("Please enter a valid number.");
        return;
      }
      // Use update with FieldValue.increment to ensure proper aggregation
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'totalSaved': FieldValue.increment(parsed),
      }).catchError((e) async {
        // If the document doesn't exist yet, create it with set
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'totalSaved': parsed,
        }, SetOptions(merge: true));
      });
      _amountController.clear();
      setState(() => _showAmountInput = false);
      _showSuccessPopup("Amount saved successfully!");
      // Debug log
      print('Saved amount $parsed to totalSaved for user ${user.uid}');
    }
  }

  Widget _buildDailySavingsInput() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.savings, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  "Daily Savings Tracker",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _amountController,
            decoration: InputDecoration(
              hintText: "Enter amount saved today",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Container(
                margin: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.save, color: Colors.white, size: 18),
                  onPressed: () {
                    _saveToDatabase(_amountController.text);
                  },
                ),
              ),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  void _startArticleChallenge(String title, String sub) async {
    int durationMinutes = 15;
    if (title.contains("30")) {
      durationMinutes = 30;
    } else if (title.contains("45")) {
      durationMinutes = 45;
    }

    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SocialMediaDelayIntroScreen(
          pdfPath: 'assets/docs/article1.pdf',
          title: title,
          durationMinutes: durationMinutes,
        ),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(2);
      _showSuccessPopup("Article read successfully!");
    }
  }

  void _startSimpleDelayChallenge(String title, int marks) async {
    int durationMinutes = 5;
    if (title.contains("10")) {
      durationMinutes = 10;
    } else if (title.contains("20")) {
      durationMinutes = 20;
    } else if (title.contains("30")) {
      durationMinutes = 30;
    }

    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDelayScreen(durationMinutes: durationMinutes),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  void _startFoodDelayEvaluateChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FoodDelayEvaluateScreen(title: title),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

  void _startMorningPhoneBanChallenge(String title, int marks) async {
    final completed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MorningPhoneBanScreen(title: title),
      ),
    );

    if (completed == true) {
      setState(() {
        _challengeChecked['${programDay}_$title'] = true;
      });
      _saveChallengeState('${programDay}_$title', true);
      _updateMarks(marks);
    }
  }

// Deprecated reminder task removed; use _buildReminderTask instead.



  Widget _buildTaskHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Today's Tasks", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: Colors.green.withOpacity(0.09), borderRadius: BorderRadius.circular(20)),
          
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
          color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
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
                : Checkbox(
              value: _challengeChecked['${programDay}_$title'] ?? false,
              onChanged: (val) {
                if (val == true) {
                  setState(() => _challengeChecked['${programDay}_$title'] = val!);
                  _saveChallengeState('${programDay}_$title', val!);
                  _updateMarks(2);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

}