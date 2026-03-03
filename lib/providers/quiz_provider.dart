import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/database_service.dart';

class QuizProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Question> _questions = [];
  bool _isLoading = false;
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _isAnswerChecked = false; // උත්තරේ චෙක් කරලාද කියලා බලන්න

  // Getters
  List<Question> get questions => _questions;
  bool get isLoading => _isLoading;
  int get currentIndex => _currentIndex;
  int get score => _score;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswerChecked => _isAnswerChecked;

  Future<void> loadQuestions() async {
    _isLoading = true;
    notifyListeners();
    _questions = await _dbService.getQuestions();
    _isLoading = false;
    notifyListeners();
  }

  void selectAnswer(int index) {
    if (!_isAnswerChecked) { // චෙක් කරලා නැත්නම් විතරක් සිලෙක්ට් කරන්න දෙන්න
      _selectedAnswerIndex = index;
      notifyListeners();
    }
  }

  // "Check Answer" button එක එබුවම ක්‍රියාත්මක වන කොටස
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
      notifyListeners();
    }
  }

  void prevQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _selectedAnswerIndex = null;
      _isAnswerChecked = false;
      notifyListeners();
    }
  }
}