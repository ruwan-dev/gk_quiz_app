import 'package:cloud_firestore/cloud_firestore.dart';

class Question {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String? imageUrl;

  Question({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    this.imageUrl,
  });

  // 🚀 DocumentSnapshot එක කෙලින්ම Question object එකක් බවට හරවන ක්‍රමය (Service එකට ඕන වෙන්නේ මේකයි)
  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Question(
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctAnswerIndex: data['correctAnswerIndex'] ?? 0,
      explanation: data['explanation'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }

  // සාමාන්‍ය Map එකකින් දත්ත ගන්නා විට
  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
      explanation: map['explanation'] ?? '',
      imageUrl: map['imageUrl'],
    );
  }
}