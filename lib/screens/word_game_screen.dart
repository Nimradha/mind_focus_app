import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

  int _daysSinceCreation() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.metadata.creationTime != null) {
      return DateTime.now().difference(user.metadata.creationTime!).inDays;
    }
    return 0;
  }

class MemoryWord {
  final String text;
  final Color color;
  final String colorName;

  MemoryWord({required this.text, required this.color, required this.colorName});
}

enum GameState { showingWords, askingQuestion, results }
enum QuestionType { text, color }

class GameQuestion {
  final int wordIndex;
  final QuestionType type;

  GameQuestion({required this.wordIndex, required this.type});
}

class WordGameScreen extends StatefulWidget {
  final int completedDaysCount;
  const WordGameScreen({super.key, required this.completedDaysCount});

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen> {
  GameState _state = GameState.showingWords;
  List<MemoryWord> _currentWords = [];
  List<GameQuestion> _questionQueue = []; // Added to handle multiple questions
  int _currentQuestionIdx = 0;           // Track which question we are on

  int _score = 0;
  int _totalQuestions = 0;
  Timer? _gameTimer;
  Timer? _cycleTimer;
  late int _secondsLeft;

  int get wordsToDisplay {
    final days = _daysSinceCreation();
    if (days < 2) return 1;
    if (days < 7) return 2;
    if (days < 14) return 3;
    return 4;
  }

  int get displayDurationSeconds {
    final days = _daysSinceCreation();
    if (days < 2) return 2;
    if (days < 7) return 4;
    if (days < 14) return 5;
    return 6;
  }

  @override
  void initState() {
    super.initState();
    final days = _daysSinceCreation();
    if (days < 7) {
      _secondsLeft = 120; // 2 minutes
    } else if (days < 14) {
      _secondsLeft = 240; // 4 minutes
    } else {
      _secondsLeft = 300; // 5 minutes
    }
    _startGame();
  }

  void _startGame() {
    _startNewCycle();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _endGame();
      }
    });
  }

  void _startNewCycle() {
    // 1. Generate random words
    _currentWords = List.generate(wordsToDisplay, (_) => _generateRandomWord());

    // 2. Prepare a question for each word shown
    _questionQueue = List.generate(wordsToDisplay, (index) {
      return GameQuestion(
        wordIndex: index,
        type: Random().nextBool() ? QuestionType.text : QuestionType.color,
      );
    });

    _currentQuestionIdx = 0;
    setState(() => _state = GameState.showingWords);

    _cycleTimer?.cancel();
    _cycleTimer = Timer(Duration(seconds: displayDurationSeconds), () {
      if (mounted) setState(() => _state = GameState.askingQuestion);
    });
  }

  MemoryWord _generateRandomWord() {
    final colors = {
      'Red': Colors.red,
      'Blue': Colors.blue,
      'Green': Colors.green,
      'Yellow': Colors.yellow,
      'Purple': Colors.purple,
    };
    // To ensure the Stroop effect, we pick random text and random color independently
    String randomText = colors.keys.elementAt(Random().nextInt(colors.length));
    String randomColorName = colors.keys.elementAt(Random().nextInt(colors.length));

    return MemoryWord(
      text: randomText,
      color: colors[randomColorName]!,
      colorName: randomColorName,
    );
  }

  void _handleAnswer(String userAnswer) {
    var currentQ = _questionQueue[_currentQuestionIdx];
    var targetWord = _currentWords[currentQ.wordIndex];

    // Check correctness based on question type
    bool isCorrect = (currentQ.type == QuestionType.text)
        ? (userAnswer == targetWord.text)
        : (userAnswer == targetWord.colorName);

    if (isCorrect) _score++;
    _totalQuestions++;

    // Check if there are more questions for this cycle
    if (_currentQuestionIdx < _questionQueue.length - 1) {
      setState(() => _currentQuestionIdx++);
    } else {
      _startNewCycle(); // All questions answered, show new words
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _cycleTimer?.cancel();
    setState(() => _state = GameState.results);
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _cycleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _state == GameState.results);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFF),
        appBar: AppBar(
          title: Text(
            "Time Left: $_secondsLeft s",
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            ),
          ),
          centerTitle: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : const Color(0xFFF8FAFF),
        ),
        body: Center(child: _buildGameContent()),
      ),
    );
  }

  Widget _buildGameContent() {
    if (_state == GameState.results) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Game Over!", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Score: $_score / $_totalQuestions", style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 30),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,   // button color
                foregroundColor: Colors.white,  // text color
              ),
              child: const Text("Back to Start")),
        ],
      );
    }

    if (_state == GameState.showingWords) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _currentWords.map((w) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            w.text,
            style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: w.color),
          ),
        )).toList(),
      );
    }

    // Question State UI
    var currentQ = _questionQueue[_currentQuestionIdx];
    String position = ["1st", "2nd", "3rd", "4th"][currentQ.wordIndex];
    String category = (currentQ.type == QuestionType.text) ? "TEXT" : "INK COLOR";

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Question ${_currentQuestionIdx + 1} of ${wordsToDisplay}",
              style: const TextStyle(color: Colors.blueGrey)),
          const SizedBox(height: 20),
          Text(
            "What was the $category of the $position word?",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: ['Red', 'Blue', 'Green', 'Yellow', 'Purple'].map((option) =>
                SizedBox(
                  width: 140,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _handleAnswer(option),
                    child: Text(option),
                  ),
                )
            ).toList(),
          ),
        ],
      ),
    );
  }
}