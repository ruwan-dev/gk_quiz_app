import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  bool _isTimerEnabled = true;
  List<Map<String, dynamic>> _wrongAnswers = [];

  // Question Timer
  Timer? _timer;
  int _secondsRemaining = 60;
  final int _totalSeconds = 60;

  // Paper Timer
  Timer? _paperTimer;
  bool _isPaperTimerEnabled = false;
  int _paperDuration = 60; 
  int _paperSecondsRemaining = 3600;
  bool _isPaperTimeUp = false;
  Function? _onPaperTimeUpCallback;

  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerChecked => _isAnswerChecked;
  int get secondsRemaining => _secondsRemaining;
  double get timerPercent => _secondsRemaining / _totalSeconds;
  bool get isTimerEnabled => _isTimerEnabled;
  List<Map<String, dynamic>> get wrongAnswers => _wrongAnswers;

  bool get isPaperTimerEnabled => _isPaperTimerEnabled;
  bool get isPaperTimeUp => _isPaperTimeUp;

  String get formattedPaperTime {
    int h = _paperSecondsRemaining ~/ 3600;
    int m = (_paperSecondsRemaining % 3600) ~/ 60;
    int s = _paperSecondsRemaining % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> loadQuestions(String categoryId, String paperId, {Function? onTimeUp}) async {
    _isLoading = true;
    _currentIndex = 0;
    _score = 0;
    _selectedAnswerIndex = null;
    _isAnswerChecked = false;
    _wrongAnswers = [];
    _isPaperTimeUp = false;
    _onPaperTimeUpCallback = onTimeUp;
    notifyListeners();

    _timer?.cancel();
    _paperTimer?.cancel();

    var catDoc = await FirebaseFirestore.instance.collection('categories').doc(categoryId).get();
    if (catDoc.exists) {
      var data = catDoc.data() as Map<String, dynamic>;
      _isTimerEnabled = data.containsKey('isTimerEnabled') ? data['isTimerEnabled'] : true;
    } else {
      _isTimerEnabled = true;
    }

    var paperDoc = await FirebaseFirestore.instance.collection('categories').doc(categoryId).collection('papers').doc(paperId).get();
    if (paperDoc.exists) {
       var data = paperDoc.data() as Map<String, dynamic>;
       _isPaperTimerEnabled = data.containsKey('isPaperTimerEnabled') ? data['isPaperTimerEnabled'] : false;
       _paperDuration = data.containsKey('paperDuration') ? data['paperDuration'] : 60;
       _paperSecondsRemaining = _paperDuration * 60;
    } else {
       _isPaperTimerEnabled = false;
    }
    
    _questions = await _dbService.getQuestions(categoryId, paperId);
    _isLoading = false;
    
    startPaperTimer();
    startTimer();
    notifyListeners();
  }

  void startPaperTimer() {
    if (!_isPaperTimerEnabled) return;
    _paperTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paperSecondsRemaining > 0) {
        _paperSecondsRemaining--;
        notifyListeners();
      } else {
        _paperTimer?.cancel();
        _isPaperTimeUp = true;
        notifyListeners();
        _onPaperTimeUpCallback?.call();
      }
    });
  }

  void startTimer() {
    _timer?.cancel();
    _secondsRemaining = _totalSeconds;
    if (!_isTimerEnabled) return;
    
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
    if (!_isAnswerChecked && !_isPaperTimeUp) {
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  void checkAnswer() {
    if (_selectedAnswerIndex != null && !_isAnswerChecked && !_isPaperTimeUp) {
      _isAnswerChecked = true;
      
      bool isCorrect = _questions[_currentIndex].correctAnswerIndex == _selectedAnswerIndex;
      if (isCorrect) {
        _score += 10;
      } else {
        _wrongAnswers.add({
          'questionText': _questions[_currentIndex].questionText,
          'selectedOption': _questions[_currentIndex].options[_selectedAnswerIndex!],
          'correctOption': _questions[_currentIndex].options[_questions[_currentIndex].correctAnswerIndex],
          'explanation': _questions[_currentIndex].explanation,
        });
      }
      notifyListeners();
    }
  }

  void nextQuestion() {
    if (_currentIndex < _questions.length - 1 && !_isPaperTimeUp) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
      startTimer();
      notifyListeners();
    }
  }

  void prevQuestion() {
    if (_currentIndex > 0 && !_isPaperTimeUp) {
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
    _paperTimer?.cancel();
    super.dispose();
  }
}