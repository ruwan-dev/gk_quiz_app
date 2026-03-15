import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';
import '../models/issue_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

      return snapshot.docs.map<Question>((doc) => Question.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> reportIssue({required String userId, required String userEmail, required String description}) async {
    try {
      await _db.collection('issues').add({
        'userId': userId,
        'userEmail': userEmail,
        'description': description,
        'createdAt': Timestamp.now(),
        'isResolved': false,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<IssueModel>> getIssues() async {
    try {
      var snapshot = await _db
          .collection('issues')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map<IssueModel>((doc) => IssueModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // 🚀 Chat Features
  Stream<QuerySnapshot> getChatMessages() {
    return _db
        .collection('global_chat')
        .orderBy('createdAt', descending: true)
        .limit(100) 
        .snapshots();
  }

  // 🚀 Auto Delete වෙන්න expiresAt එකතු කළා
  Future<bool> sendChatMessage({required String userId, required String userName, required String text, bool isSupport = false}) async {
    try {
      await _db.collection('global_chat').add({
        'userId': userId,
        'userName': userName,
        'text': text,
        'isSupport': isSupport, 
        'createdAt': Timestamp.now(),
        // 🚀 දැනට තියෙන වෙලාවට පැය 24ක් එකතු කරලා සේව් කරනවා
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))), 
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}