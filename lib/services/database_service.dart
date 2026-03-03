import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Firebase එකේ 'quizzes' collection එකෙන් ප්‍රශ්න ටික stream එකක් විදියට ගන්නවා
  Stream<List<Question>> getQuestions() {
    return _db.collection('quizzes').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Question.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}