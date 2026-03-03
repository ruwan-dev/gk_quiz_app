import 'package:flutter/material.dart';
import 'dart:async';

class QuizProvider with ChangeNotifier {
  int _score = 0;
  int _currentIndex = 0;
  int _seconds = 30; // එක ප්‍රශ්නයකට තත්පර 30 යි
  Timer? _timer;

  // Getters
  int get score => _score;
  int get currentIndex => _currentIndex;
  int get seconds => _seconds;

  void startTimer(Function onTimeUp) {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        _seconds--;
        notifyListeners();
      } else {
        _timer?.cancel();
        onTimeUp(); // වෙලාව ඉවර වුණොත් කරන දේ
      }
    });
  }

  void checkAnswer(int selectedIndex, int correctIndex) {
    if (selectedIndex == correctIndex) {
      _score += 10; // ලකුණු 10 ක් එකතු වෙනවා
    }
    nextQuestion();
  }

  void nextQuestion() {
    if (_currentIndex < 49) { // ප්‍රශ්න 50 සීමාව
      _currentIndex++;
      _seconds = 30;
      notifyListeners();
    } else {
      // Game Over Logic
    }
  }

  void skipQuestion() {
    nextQuestion(); // ලකුණු දෙන්නේ නැතුව ඊළඟ එකට යනවා
  }
}