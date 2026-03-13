import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String id;
  final String userId;
  final String userEmail;
  final String description;
  final Timestamp createdAt;
  final bool isResolved;

  IssueModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.description,
    required this.createdAt,
    this.isResolved = false,
  });

  factory IssueModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return IssueModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      description: data['description'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isResolved: data['isResolved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'description': description,
      'createdAt': createdAt,
      'isResolved': isResolved,
    };
  }
}
