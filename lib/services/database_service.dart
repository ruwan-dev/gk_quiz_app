import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Question>> getQuestions() async {
    try {
      // මෙන්න මෙතනයි 'quizzes' collection එක පාවිච්චි කරන්නේ
      QuerySnapshot snapshot = await _db.collection('quizzes').get();
      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      print("Firebase Fetch Error: $e");
      return [];
    }
  }
}