import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'details.dart';
import '../services/notification_service.dart';
import 'task_intro_screen.dart';
import '../widgets/animated_page_route.dart';
import 'achievement_screen.dart';
import 'package:audioplayers/audioplayers.dart' hide Source;
import 'word_game_screen.dart';
import 'running_timer_screen.dart';
import 'imagination_timer_screen.dart';
import 'fullscreen_completion_screen.dart';


class Exercise {
  final String title;
  final String subtitle;
  final String instructions;
  final String imagePath;
  final String duration;
  final String completionMessage;
  final VoidCallback onStart;
  final bool isEnabled;
  final String? disabledText;

  Exercise({
    required this.title,
    required this.subtitle,
    required this.instructions,
    required this.imagePath,
    required this.duration,
    required this.completionMessage,
    required this.onStart,
    this.isEnabled = true,
    this.disabledText,
  });
}

// 1. THE WIDGET CLASS
class HomeScreen extends StatefulWidget {
  final VoidCallback? onTaskPressed; // Add this
  const HomeScreen({super.key, this.onTaskPressed});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// 2. THE STATE CLASS (This handles all the logic and UI)
class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _homePageSoundPlayer = AudioPlayer();
  bool _isMusicPlaying = false;

  int _completedDaysCount = 0;
  // This lives inside the State class now
  List<bool> _isDoneList = [false, false, false, false];
  bool _isLoading = true;
  bool _morningCongratsShown = false;
  bool _eveningCongratsShown = false;
  bool _allCongratsShown = false;

  // Savings tracker
  double _totalSaved = 0.0;
  int _programDay = 1;
  StreamSubscription<DocumentSnapshot>? _savingsSubscription;

  // Word-by-word heading animation
  int _visibleWordCount = 0;
  Timer? _wordTimer;

  @override
  void initState() {
    super.initState();
    _playHomePageSound();
    _loadUserProgress();
    _startHeadingAnimation();
    _listenToSavings();
  }

  /// Animates the heading text word-by-word with a 300ms stagger
  void _startHeadingAnimation() {
    final heading = DateTime.now().hour < 18
        ? "Tasks to be done before 6 PM"
        : "Tasks to be done after 6 PM";
    final wordCount = heading.split(' ').length;

    _wordTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (_visibleWordCount >= wordCount) {
        timer.cancel();
        return;
      }
      setState(() {
        _visibleWordCount++;
      });
    });
  }

  /// Plays the home page welcome sound once when the screen loads
  void _playHomePageSound() async {
    try {
      await _homePageSoundPlayer.setReleaseMode(ReleaseMode.stop);
      await _homePageSoundPlayer.play(AssetSource('audio/home_page_sound.mpeg'));
      debugPrint("Home page sound played");
    } catch (e) {
      debugPrint("Error playing home page sound: $e");
    }
  }

  /// Listens to Firestore in real-time for changes to totalSaved so the banner refreshes immediately.
  void _listenToSavings() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _savingsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        if (mounted) {
          setState(() {
            _totalSaved = (data['totalSaved'] ?? 0).toDouble();
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _savingsSubscription?.cancel();
    super.dispose();
  }

  void _loadUserProgress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(const GetOptions(source: Source.server));
        debugPrint("Firestore: loaded document. isFromCache = ${doc.metadata.isFromCache}");
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;

          String today = DateTime.now().toString().split(' ')[0];
          String? lastCompletionDate = data['lastCompletionDate'];
          // The date the user last clicked ANY checkbox
          String? lastActiveDate = data['lastActiveDate'];

          // Calculate program day
          DateTime? creationTimeFull = user.metadata.creationTime;
          int computedProgramDay = 1;
          if (creationTimeFull != null) {
            DateTime now2 = DateTime.now();
            DateTime creationDate2 = DateTime(creationTimeFull.year, creationTimeFull.month, creationTimeFull.day);
            DateTime todayDate2 = DateTime(now2.year, now2.month, now2.day);
            computedProgramDay = todayDate2.difference(creationDate2).inDays + 1;
          }

          setState(() {
            _completedDaysCount = data['completedDaysCount'] ?? 0;
            _totalSaved = (data['totalSaved'] ?? 0).toDouble();
            _programDay = computedProgramDay;
            
            List<bool> savedList = List<bool>.from(data['lastDoneList'] ?? [false, false, false, false]);
            int doneCount = savedList.where((item) => item).length;
            
            bool isNewDay = lastActiveDate != today;

            if (isNewDay) {
              if (doneCount == 4) {
                // Completed yesterday's tasks, fresh start today
                _isDoneList = [false, false, false, false];
              } else {
                // Didn't finish yesterday's tasks
                DateTime? creationTime = user.metadata.creationTime;
                int daysSinceCreation = creationTime != null ? DateTime.now().difference(creationTime).inDays : 0;
                
                if (daysSinceCreation < 14) {
                  // First 2 weeks since account creation: always give a fresh start
                  _isDoneList = [false, false, false, false];
                } else {
                  // After 2 weeks: carry over uncompleted tasks
                  _isDoneList = savedList;
                }
              }
              // Sync the potentially new start state to Firebase
              _updateFirebaseList();
            } else {
              // Same day, resume where left off
              _isDoneList = savedList;
            }

            // Evening Meditation Reset Logic (only if they have tasks done)
            bool isAfter6PM = DateTime.now().hour >= 18;
            bool hasCompletedMorningTasks = _isDoneList.length >= 3 && _isDoneList[0] && _isDoneList[1] && _isDoneList[2];
            bool hasResetMeditation = data['eveningMeditationResetDate'] == today;

            if (isAfter6PM && hasCompletedMorningTasks && !hasResetMeditation) {
              _isDoneList[0] = false; // Uncheck Meditation
              FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                'lastDoneList': _isDoneList,
                'eveningMeditationResetDate': today,
              }, SetOptions(merge: true));
            }

            // Initialize the congratulations shown flags based on loaded state
            _morningCongratsShown = _isDoneList.length >= 3 && _isDoneList[0] && _isDoneList[1] && _isDoneList[2];
            _eveningCongratsShown = _isDoneList.length >= 4 && _isDoneList[0] && _isDoneList[3];
            _allCongratsShown = _morningCongratsShown && _isDoneList[3];
            
            _isLoading = false;

          });

        } else {
          // If the document doesn't exist (new user), stop loading so the UI can render
          setState(() => _isLoading = false);
        }
        _scheduleDailyReminder();
        _checkAndShowEveningPreview(user);
      } catch (e) {
        debugPrint("Error loading: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  void _scheduleDailyReminder() {
    NotificationService().scheduleDaily10AMCheck(_isDoneList);
    NotificationService().scheduleDaily4PMCheck(_isDoneList);
    NotificationService().scheduleDaily6PMCheck(_isDoneList);
  }

  /// Checks if current time is past 6 PM and shows a preview popup of tomorrow's challenges once per day.
  Future<void> _checkAndShowEveningPreview(User user) async {
    final now = DateTime.now();
    if (now.hour < 18) return; // Only trigger after 6:00 PM

    final todayStr = now.toString().split(' ')[0];
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getString('evening_preview_shown_date');

    if (lastShown == todayStr) return; // Already shown today

    // Calculate current program day based on account creation time
    DateTime? creationTime = user.metadata.creationTime;
    int programDay = 1;
    if (creationTime != null) {
      DateTime creationDate = DateTime(creationTime.year, creationTime.month, creationTime.day);
      DateTime todayDate = DateTime(now.year, now.month, now.day);
      programDay = todayDate.difference(creationDate).inDays + 1;
    }
    int tomorrowDay = programDay + 1;
    List<String> tomorrowChallenges = _getChallengesForDay(tomorrowDay);

    await prefs.setString('evening_preview_shown_date', todayStr);

    if (mounted) {
      _showTomorrowPreviewDialog(tomorrowDay, tomorrowChallenges);
    }
  }

  /// Renders a dialog showing tomorrow's upcoming challenges.
  void _showTomorrowPreviewDialog(int tomorrowDay, List<String> challenges) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.wb_twilight, color: Colors.amber, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tomorrow's Preview",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          Text(
                            "Day $tomorrowDay Challenges",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  "Here is a sneak peek at the challenges scheduled for you tomorrow in your Plan screen. Prepare your mind!",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: challenges.map((challenge) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.bolt, color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                challenge,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black90,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      "I'm Ready!",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Maps a program day index to its corresponding scheduled challenges.
  List<String> _getChallengesForDay(int day) {
    switch (day) {
      case 1:
      case 2:
        return ["No challenges for the first 2 days. Get ready!"];
      case 3:
        return ["15 min social media delay"];
      case 4:
        return ["Delay 5 minutes from taking favorite food item", "No-scroll during meals"];
      case 5:
        return ["Delay 5 minutes from taking favorite food item", "10 min social media delay"];
      case 6:
        return ["Delay 10 minutes from taking favorite food item", "No complaint day"];
      case 7:
        return ["Never buy the food that you feel to buy (Build Savings)"];
      case 8:
        return ["10 min meditation – focus on breathing", "Mind‑drift reminder"];
      case 9:
        return ["30 min social media delay"];
      case 10:
        return ["Delay 10 minutes from taking favorite food item", "No social media scrolling at all"];
      case 11:
        return ["10 min meditation – focus on breathing"];
      case 12:
        return ["20 min food delay – Evaluate cost and health value", "No external food day"];
      case 13:
        return ["15 min social media delay", "No complaint day"];
      case 14:
        return ["Sudden urge pause", "3‑minute pause"];
      case 15:
        return ["10 min meditation", "No social media scrolling at all"];
      case 16:
        return ["30 min food delay – Evaluate cost and health value"];
      case 17:
        return ["30 min social media delay", "No external food day"];
      case 18:
        return ["10 min meditation"];
      case 19:
        return ["Morning phone ban - no phone for 1st 30 min", "Call out cravings"];
      case 20:
        return ["Master Your Weakness", "No complaint day"];
      case 21:
        return ["30 min social media delay"];
      case 22:
        return ["15 min meditation", "No social media scrolling at all"];
      case 23:
        return ["Morning phone ban - no phone for 1 hour after waking"];
      case 24:
        return ["30 min food delay – Evaluate identity", "No external food day"];
      case 25:
        return ["15 min meditation"];
      case 26:
        return ["Call out cravings"];
      case 27:
        return ["The Ultimate Test of Will", "Decide your wait time"];
      case 28:
        return ["15 min meditation", "Be your own coach"];
      case 29:
        return ["Track Your Mental Energy"];
      case 30:
        return ["Month reflection", "Full dopamine audit"];
      default:
        return ["Rest Day - Keep your mindset sharp!"];
    }
  }

  void _updateFirebaseList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        String today = DateTime.now().toString().split(' ')[0];
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastDoneList': _isDoneList,
          'lastActiveDate': today,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Error updating list: $e");
      }
    }
  }

  List<Exercise> _getDynamicExercises() {
    // Instructions change every 3 SUCCESSFUL days
    int phase = _completedDaysCount ~/ 3;
    bool isBefore6PM = DateTime.now().hour < 18;

    return [
      Exercise(
        title: "Meditation",
        subtitle: "Daily Mindset",
        instructions: _getMeditationInstructions(),
        imagePath: "assets/images/meditation.jpeg",
        duration: "${_getMeditationDurationMinutes()} Mins",
        completionMessage: "Zen achieved! 🧘‍♂️",
        onStart: _playMeditationMusic,
        isEnabled: true,
        disabledText: null,
      ),
      Exercise(
        title: "Word Memory Game",
        subtitle: "Cognitive Speed",
        instructions: _daysSinceCreation() < 2
            ? "1 word is displayed for 2 seconds. Next a question is asked related to that word.Select your answer out of 4 choices."
            : _daysSinceCreation() < 7
                ? "2 words are displayed for 4 seconds. Next 2 questions are asked related to those 2 words.Select your answer out of 4 choices."
                : _daysSinceCreation() < 14
                    ? "3 words are displayed for 5 seconds. Next 3 questions are asked related to those 3 words.Select your answer."
                    : "4 words are displayed for 6 seconds. Next 4 questions are asked related to those 4 words.Select your answer.",
        imagePath: "assets/images/memory.png",
        duration: _daysSinceCreation() < 7 ? "2 Mins" : _daysSinceCreation() < 14 ? "4 Mins" : "5 Mins",
        completionMessage: "Memory sharpened! 🧠",
        isEnabled: isBefore6PM,
        disabledText: isBefore6PM ? null : "To be done before 6pm",
        onStart: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WordGameScreen(
                completedDaysCount: _completedDaysCount, // Pass the progress
              ),
            ),
          );
          // Later: Navigator.push(context, MaterialPageRoute(builder: (context) => TimerScreen(minutes: 10)));
        },
      ),
      Exercise(
        title: "Running Exercise",
        subtitle: "Cardio & Focus",
        instructions: _getRunningInstructions(),
        imagePath: "assets/images/run.png",
        duration: _daysSinceCreation() < 14 ? "5 Mins" : "10 Mins",
        completionMessage: "Endorphins released! 🏃‍♂️",
        isEnabled: isBefore6PM,
        disabledText: isBefore6PM ? null : "To be done before 6pm",
        onStart: () async{
          final isFinished = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RunningTimerScreen(
                completedDaysCount: _completedDaysCount,
              ),
            ),
          );

          if (isFinished == true) {
            // Logic to mark the exercise as done in your home screen list
            _markExerciseAsDone("Running");
          }
          // Later: Navigator.push(context, MaterialPageRoute(builder: (context) => TimerScreen(minutes: 10)));
        },
      ),
      Exercise(
        title: _getFourthExerciseTitle(),
        subtitle: "Creative Agility",
        instructions: _getFourthExerciseInstructions(),
        imagePath: _getFourthExerciseImagePath(),
        duration: "5 Mins",
        completionMessage: "Creativity flowing! 🎨",
        isEnabled: !isBefore6PM,
        disabledText: !isBefore6PM ? null : "To be done after 6pm",
        onStart: () async{
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImaginationTimerScreen(
                completedDaysCount: _completedDaysCount,
                instruction: _getFourthExerciseInstructions(),
              ),
            ),
          );

          if (result == true) {
            _markExerciseAsDone(_getFourthExerciseTitle());
          }
          // Later: Navigator.push(context, MaterialPageRoute(builder: (context) => TimerScreen(minutes: 10)));
        },
      ),
    ];
  }

  Future<void> _showCompletionImageIfMatched(BuildContext context, String title) async {
    String? imagePath;
    String titleLower = title.toLowerCase();
    
    if (titleLower.contains("meditation")) {
      imagePath = "assets/images/task1_complete.png";
    } else if (titleLower.contains("running")) {
      imagePath = "assets/images/running_complete.png";
    } else if (titleLower.contains("word") || titleLower.contains("memory")) {
      imagePath = "assets/images/wordmem_complete.png";
    } else if (titleLower.contains("somatic") ||
        titleLower.contains("labeling") ||
        titleLower.contains("imagination")) {
      imagePath = "assets/images/task4_complete.png";
    }

    if (imagePath != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FullScreenCompletionScreen(
            imagePath: imagePath!,
            title: title,
          ),
        ),
      );
    }
  }

  void _showSuccessPopup(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _checkCompletion() async {
    bool morningCompleted = _isDoneList[0] && _isDoneList[1] && _isDoneList[2];
    bool eveningCompleted = _isDoneList[0] && _isDoneList[3];
    bool allCompleted = morningCompleted && _isDoneList[3];

    // Reset congrats shown flags if user unchecks any task
    if (!morningCompleted) _morningCongratsShown = false;
    if (!eveningCompleted) _eveningCongratsShown = false;
    if (!allCompleted) _allCongratsShown = false;

    // Case 1: All tasks for the day are completed (either finished normally, or finished the morning carryover)
    if (allCompleted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String today = DateTime.now().toString().split(' ')[0];
        try {
          // Successful Day! Increment counter and Reset checks for tomorrow
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'completedDaysCount': FieldValue.increment(1),
            'lastCompletionDate': today, // Store the date he finished
            'lastDoneList': _isDoneList,
            'lastActiveDate': today,
          }, SetOptions(merge: true));

          setState(() {
            _completedDaysCount++;
          });
        } catch (e) {
          debugPrint("Error updating completion: $e");
        }
      }
      
      if (!_allCongratsShown) {
        _allCongratsShown = true;
        _eveningCongratsShown = true;
        _morningCongratsShown = true;
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AchievementScreen(
              message: "You've reached your daily mindfulness goal.",
            ),
          ),
        );
      }
      return;
    }

    // Case 2: Only the morning tasks are completed (3 tasks before 6pm checked)
    if (morningCompleted && !_morningCongratsShown) {
      _morningCongratsShown = true;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AchievementScreen(
            message: "You've successfully completed your Morning Tasks",
          ),
        ),
      );
      return;
    }

    // Case 3: Only the evening tasks are completed (2 tasks after 6pm checked)
    if (eveningCompleted && !_eveningCongratsShown) {
      _eveningCongratsShown = true;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AchievementScreen(
            message: "You've successfully completed your Evening Tasks",
          ),
        ),
      );
      return;
    }
  }

  void _playMeditationMusic() async {
    if (_isMusicPlaying) {
      // If already playing, stop it (Toggle behavior)
      await _audioPlayer.stop();
      setState(() => _isMusicPlaying = false);
      debugPrint("Music Stopped manually");
    } else {
      try {
        // 1. Play the asset
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.play(AssetSource('audio/meditation.mp3'));
        setState(() => _isMusicPlaying = true);
        debugPrint("Music Started");

        // 2. Set a timer to stop after duration
        int durationMinutes = _getMeditationDurationMinutes();
        Future.delayed(Duration(minutes: durationMinutes), () async {
          if (_isMusicPlaying) {
            await _audioPlayer.stop();
            setState(() => _isMusicPlaying = false);
            _showSuccessPopup("Meditation session complete! 🧘‍♀️");
          }
        });

      } catch (e) {
        debugPrint("Error playing audio: $e");
        _showSuccessPopup("Could not load music file.");
      }
    }
  }

  // CRITICAL: Always clean up the player when the screen is closed
  @override
  void dispose() {
    _wordTimer?.cancel();
    _audioPlayer.dispose();
    _homePageSoundPlayer.dispose();
    super.dispose();
  }

  void _markExerciseAsDone(String title) async {
    // 1. Find the index of the exercise by its title
    final exercises = _getDynamicExercises();
    int index = exercises.indexWhere((e) => e.title.toLowerCase().contains(title.toLowerCase()));

    // 2. If found and not already done, update the state
    if (index != -1 && !_isDoneList[index]) {
      setState(() {
        _isDoneList[index] = true;
      });
      _scheduleDailyReminder();

      // 3. Sync to Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          String today = DateTime.now().toString().split(' ')[0];
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'lastDoneList': _isDoneList,
            'lastActiveDate': today,
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Error updating task: $e");
        }
      }

      // 4. Show the green success bar and check if the whole day is finished
      await _showCompletionImageIfMatched(context, exercises[index].title);
      _showSuccessPopup(exercises[index].completionMessage);
      _checkCompletion();
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final dynamicExercises = _getDynamicExercises();
    // Calculate progress for the Daily Goal card
    int doneCount = _isDoneList.where((item) => item).length;
    double progress = doneCount / _isDoneList.length;
    int percentage = (progress * 100).round();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              if (_programDay >= 7) _buildSavingsBanner(),
              if (_programDay >= 7) const SizedBox(height: 20),
              _buildWelcomeCard(),
              const SizedBox(height: 25),
              // Pass the progress data to the card
              _buildDailyGoalCard(doneCount, progress,percentage),
              const SizedBox(height: 30),
              _buildExerciseSection(dynamicExercises),
              const SizedBox(height: 25),
              _buildAchievementCard(),
            ],
          ),
        ),
      ),

    );
  }

  // --- 1. Top Header ---
  Widget _buildHeader() {
    final User? user = FirebaseAuth.instance.currentUser;
    String displayName = user?.email != null ? user!.email!.split('@')[0] : "Friend";
    // Truncate long display names to first 5 characters with ellipsis
    String shortDisplayName = displayName.length > 5 ? '${displayName.substring(0,5)}...' : displayName;
    DateTime now = DateTime.now();
    int hour = now.hour;
    String greeting;
    if (hour >= 12 && hour < 17) {
      greeting = "Good afternoon";
    } else if (hour >= 17) {
      greeting = "Good evening";
    } else {
      greeting = "Good morning";
    }
    List<String> months = [
      "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
      "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"
    ];
    String formattedDate = "${months[now.month - 1]} ${now.day}, ${now.year}";

    return Row(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundImage: AssetImage('assets/images/user.png'),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text("$greeting, $shortDisplayName!",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  // --- 1b. Savings Banner (Day 7+) ---
  Widget _buildSavingsBanner() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Format the amount nicely
    String formattedAmount = _totalSaved == _totalSaved.truncateToDouble()
        ? _totalSaved.toStringAsFixed(0)
        : _totalSaved.toStringAsFixed(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1B4332), const Color(0xFF2D6A4F)]
              : [const Color(0xFF40916C), const Color(0xFF52B788)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF40916C).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Coin icon container
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.savings_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TOTAL SAVINGS SO FAR",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Rs. $formattedAmount",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Day badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  "DAY",
                  style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
                Text(
                  "$_programDay",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. Welcome Card ---
  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Welcome to MindGym!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Your daily partner for mental fitness. Train your focus, memory and cognitive agility with fun,bite-sized exercises.",
              style: TextStyle(color: Colors.grey[600], height: 1.5)),
        ],
      ),
    );
  }

  // --- 3. Daily Goal Card (Updated to take variables) ---
  Widget _buildDailyGoalCard(int doneCount, double progress, int percentage) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Daily Goal", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Great job! You've unlocked today's customization bonus."),
                const SizedBox(height: 12),
                _buildStatusBadge((progress * 100).round()),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80, width: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.white,
                  color: Colors.green,
                ),
              ),
              Text("$doneCount/4", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(int percent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
    color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
    borderRadius: BorderRadius.circular(20),
  ),
      child:  Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, color: Colors.green, size: 16),
          SizedBox(width: 5),
          Text("+$percent% today", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- 4. Exercise Section ---
  Widget _buildExerciseSection(List<Exercise> exercises) {
    bool isBefore6PM = DateTime.now().hour < 18;

    // Determine which indices to show based on time of day:
    // Exercises 0-2 (Meditation, Word Game, Running) are for before 6PM.
    // Exercises 0 and 3 (Meditation + evening exercise) are for after 6PM.
    List<int> visibleIndices = isBefore6PM
        ? [0, 1, 2]   // Morning/afternoon: show first three
        : [0, 3];     // Evening: show Meditation + the 6PM+ exercise

    String heading = isBefore6PM
        ? "Tasks to be done before 6 PM"
        : "Tasks to be done after 6 PM";

    final words = heading.split(' ');
    final headingColor = isBefore6PM ? Colors.blue.shade700 : Colors.indigo.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Animated word-by-word heading
        Wrap(
          children: [
            for (int i = 0; i < words.length; i++)
              AnimatedOpacity(
                opacity: i < _visibleWordCount ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: AnimatedSlide(
                  offset: i < _visibleWordCount
                      ? Offset.zero
                      : const Offset(0, 0.5),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      words[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: headingColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (int i in visibleIndices)
          _exerciseTile(i, exercises[i]),
      ],
    );
  }

  Widget _exerciseTile(int index, Exercise exercise) {
    bool isDone = _isDoneList[index];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Theme.of(context).brightness == Brightness.dark
            ? Border.all(color: Colors.green.shade100)
            : Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 1. Checkbox: This is now the ONLY place to toggle completion
          GestureDetector(
            onTap: !exercise.isEnabled ? null : () async{
              setState(() {
               _isDoneList[index] = !_isDoneList[index];
              });
              _scheduleDailyReminder();
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                try {
                  String today = DateTime.now().toString().split(' ')[0];
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                   'lastDoneList': _isDoneList,
                   'lastActiveDate': today,
                  }, SetOptions(merge: true));
                } catch (e) {
                  debugPrint("Error saving checkbox state: $e");
                }
              }
                if (_isDoneList[index]) {
                  await _showCompletionImageIfMatched(context, exercise.title);
                  _showSuccessPopup(exercise.completionMessage);
                  _checkCompletion();
                }
              },

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0), // Increases tap area
              child: Icon(
                isDone ? Icons.check_circle : Icons.circle_outlined,
                color: isDone ? Colors.green : (exercise.isEnabled ? Colors.grey : Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(width: 15),

          // 2. Exercise Info (Tapping here does nothing now)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title (full name)
                Text(
                  exercise.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: exercise.isEnabled
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black)
                        : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                ),
                Text(exercise.subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (!exercise.isEnabled && exercise.disabledText != null)
                  Text(exercise.disabledText!, style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          const Spacer(),

          // 3. Dynamic Button/Badge
          isDone
              ? _buildBadge("DONE", Colors.green.shade100, Colors.green)
              : ElevatedButton(
            onPressed: !exercise.isEnabled ? null : () async {

              // Navigate to intro screen (first 3 days) or directly to details
              final result = await Navigator.push(
                context,
                AnimatedPageRoute(
                  page: _shouldShowIntro(index)
                      ? TaskIntroScreen(exercise: exercise)
                      : TaskDetailScreen(exercise: exercise),
                ),
              );

              // If they clicked "Mark as Done" in details.dart
              if (result == true) {
                setState(() {
                  _isDoneList[index] = true;
                });
                _scheduleDailyReminder();

                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  try {
                    String today = DateTime.now().toString().split(' ')[0];
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .set({
                      'lastDoneList': _isDoneList, // This sends the new 'true' state
                      'lastActiveDate': today,
                    }, SetOptions(merge: true));
                  } catch (e) {
                    debugPrint("Error saving task details: $e");
                  }
                }

                await _showCompletionImageIfMatched(context, exercise.title);
                _showSuccessPopup(exercise.completionMessage);
                _checkCompletion();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              side: BorderSide(color: Colors.green.shade100),
            ),
            child: Text("Start", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.green.shade800 : Colors.green)),
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  // --- 5. Achievement Card ---
  Widget _buildAchievementCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.stars, color: Colors.orange),
              SizedBox(width: 10),
              Text("ACHIEVEMENT UNLOCKED", style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 10),
          Text("Master Your Momentum",
              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("After completing today's exercises now it's time to plan rest of your day with extra training and plans", style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 20),
          _actionButton("Today's Tasks", null, Colors.green, Colors.white,() {
            if (widget.onTaskPressed != null) {
              widget.onTaskPressed!(); // This triggers the tab switch in MainWrapper
            }
          }),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData? icon, Color bg, Color text, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent, // Keeps the underlying style
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15), // Matches your container
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: text, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(color: text, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Returns true if the intro image screen should be shown for this task.
  // Intro is only shown for the first 3 days that each task appears.
  bool _shouldShowIntro(int index) {
    int days = _daysSinceCreation();

    // Tasks 0, 1, 2 (Meditation, Word Memory, Running): appear from day 0
    if (index <= 2) {
      return days < 3;
    }

    // Task 3 (4th exercise) changes based on days since creation:
    // Somatic Tracking (days 0-6): show intro on days 0-2
    if (days < 7) {
      return days < 3;
    }
    // Labeling (days 7-13): show intro on days 7-9
    if (days < 14) {
      return days < 10;
    }
    // Imagination Training (days 14+): show intro on days 14-16
    return days < 17;
  }

  // Returns the number of days since the user account was created.
  int _daysSinceCreation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.metadata.creationTime != null) {
      return DateTime.now().difference(user.metadata.creationTime!).inDays;
    }
    return 0;
  }

  int _getMeditationDurationMinutes() {
    int days = _daysSinceCreation();
    if (days < 7) return 5;
    if (days < 14) return 10;
    return 15;
  }

  String _getMeditationInstructions() {
    int mins = _getMeditationDurationMinutes();
    return "Give your mind a break.Sit in a quiet place where you won't be interrupted. Let your shoulders drop and rest your hands loosely in your lap.Gently close your eyes.Bring your full attention to your breathing for $mins minutes.";
  }

  String _getRunningInstructions() {
    int day = _daysSinceCreation() + 1;

    // --- 5 MINUTE SESSIONS (Days 1 - 15) ---
    if (day <= 3) return "Start counting from 500.Decrease by exactly 3 at each step.Continue counting down until you reach 0.(500, 497, 494...).Tap the start button below to kick off your daily routine.Let's make progress together, one step at a time. ";
    if (day <= 6) return "Start counting from 500.Decrease by exactly 7 at each step.Continue counting down until you reach 0(500, 493, 486...).Tap the start button below to kick off your daily routine.Let's make progress together, one step at a time. ";
    if (day <= 9) return "Start counting from 500.Decrease by exactly 13 at each step.Continue counting down until you reach 0 (500, 487, 474...).";
    if (day <= 12) return "Start counting from 1000.Decrease by exactly 3 at each step.Continue counting down until you reach 0 (1000, 997, 994...).";
    if (day <= 15) return "Start counting from 1000.Decrease by exactly 7 at each step.Continue counting down until you reach 0 (1000, 993, 986...).";
    if (day <= 18) return "Start counting from 1000.Decrease by exactly 13 at each step.Continue counting down until you reach 0 (1000, 987, 974...).";
    if (day <= 24) return "Start counting from 1000.Decrease from 1 to 5 sequentially (1000, 999, 997, 994,990,985) then repeat decreasing again from 1 to 5 (984,982,979...)";
    if (day <= 30) return "Start counting from 1000.Decrease from 1 to 10 sequentially (1000, 999, 997, 994...) then repeat decreasing again from 1 to 10";

    
    return "FINAL CHALLENGE: Start counting from any random number.Decrease from 1 to 15 sequentially after every breath.";
  }

  String _getFourthExerciseTitle() {
    final user = FirebaseAuth.instance.currentUser;
    int days = 0;
    if (user != null && user.metadata.creationTime != null) {
      days = DateTime.now().difference(user.metadata.creationTime!).inDays;
    }
    if (days < 7) return "Somatic tracking";
    if (days < 14) return "Labeling";
    return "Imagination Training";
  }

  String _getFourthExerciseImagePath() {
    String title = _getFourthExerciseTitle().toLowerCase();
    if (title.contains("somatic")) {
      return "assets/images/somaticdetail.png";
    } else if (title.contains("labeling")) {
      return "assets/images/labeldetail.png";
    }
    return "assets/images/imagination.png";
  }

  String _getFourthExerciseInstructions() {
    if (_completedDaysCount < 7) {
      return 'Focus on your physical sensation for 5 minutes.you observe the sensation without judgement,telling yourself "This is just a sensation".';
    }
    if (_completedDaysCount < 14) {
      return "Focus on your mental imagery and hold the vision clearly for 5 minutes.Label them whether it is a fear,anger,affection,kindness or is it a good or bad Thought.";
    }
    return _getImaginationInstructions();
  }

  String _getImaginationInstructions() {
    int day = _completedDaysCount + 1;

    if (day <= 2) return "Imagine you are successful in your future. You have earned everything you ever wanted. Feel the pride.";
    if (day <= 4) return "Visualize your future life: Honestly imagine both the good and bad things that could happen.";
    if (day <= 7) return "Close your eyes and visualize yourself waking up early tomorrow and doing pushups. See every movement.";
    if (day <= 14) return "As you imagined in the previous days from today onwards wake up early morning and do pushups for 5 minutes.";
    if (day <= 21) return "Imagine a favorite item you love. Practice making your mindset strong enough to say 'no' to it.";
    return "From today onwards start working hard to achieve all your future goals as it is.Plan your day effectively within this 5 minutes and work according to it";
  }

}