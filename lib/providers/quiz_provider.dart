import 'package:flutter/material.dart';
import 'dart:async';
import '../models/question_model.dart';
import '../services/database_service.dart';

class QuizProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Question> _questions = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerChecked = false;

  Timer? _timer;
  int _secondsRemaining = 60;
  final int _totalSeconds = 60;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerChecked => _isAnswerChecked;
  int get secondsRemaining => _secondsRemaining;
  double get timerPercent => _secondsRemaining / _totalSeconds;

  Future<void> loadQuestions(String categoryId, String paperId) async {
    _isLoading = true;
    _currentIndex = 0;
    _score = 0;
    _selectedAnswerIndex = null;
    _isAnswerChecked = false;
    notifyListeners();
    
    _questions = await _dbService.getQuestions(categoryId, paperId);
    _isLoading = false;
    startTimer();
    notifyListeners();
  }

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = _totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _timer?.cancel();
        handleTimeUp();
      }
    });
  }

  void handleTimeUp() {
    if (_currentIndex < _questions.length - 1) {
      nextQuestion();
    }
  }

  void selectAnswer(int index) {
    if (!_isAnswerChecked) {
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  void checkAnswer() {
    if (_selectedAnswerIndex != null && !_isAnswerChecked) {
      _isAnswerChecked = true;
      if (_questions[_currentIndex].correctAnswerIndex == _selectedAnswerIndex) {
        _score += 10;
      }
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
      startTimer();
      notifyListeners();
    }
  }

  void prevQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
      startTimer();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}