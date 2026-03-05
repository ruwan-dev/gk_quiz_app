import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Question>> getQuestions(String categoryId, String paperId) async {
    try {
      // Path: categories -> gk -> papers -> paper_01 -> questions
      QuerySnapshot snapshot = await _db
          .collection('categories')
          .doc(categoryId)
          .collection('papers')
          .doc(paperId)
          .collection('questions')
          .get();
          
      return snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      print("Firebase Fetch Error: $e");
      return [];
    }
  }
}