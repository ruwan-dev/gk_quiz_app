import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🚀 ප්‍රශ්න ලබාගන්නා ෆන්ක්ෂන් එක
  Future<List<Question>> getQuestions(String categoryId, String paperId) async {
    try {
      var snapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('papers')
          .doc(paperId)
          .collection('questions')
          .orderBy('createdAt')
          .get();

      // මෙතනදී .map<Question> කියලා දාන එකෙන් අර Type Error එක නැති වෙනවා
      return snapshot.docs.map<Question>((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching questions: $e");
      return [];
    }
  }

  // වෙනත් දත්ත ලබාගැනීමේ ෆන්ක්ෂන් මෙතනට එක් කරන්න පුළුවන්...
}