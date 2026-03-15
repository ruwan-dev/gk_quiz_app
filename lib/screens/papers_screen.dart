import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;
import 'quiz_screen.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../utils/app_constants.dart';

class PapersScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final Function(String) onNavigate;

  const PapersScreen({
    super.key, 
    required this.categoryId, 
    required this.categoryName,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, userSnap) {
        bool isUserPremium = false;
        if (userSnap.hasData && userSnap.data!.exists) {
          final userData = userSnap.data!.data() as Map<String, dynamic>?;
          isUserPremium = userData?['isPremium'] ?? false;
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text(
              "$categoryName Papers", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)
            ),
            backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .doc(categoryId)
                .collection('papers')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Center(child: Text("Error loading papers", style: TextStyle(color: Colors.white)));
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
              }
              
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !(data.containsKey('isVisible') && data['isVisible'] == false);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No papers available for this category.", style: TextStyle(color: Colors.white70))
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final paper = docs[index];
                  final paperData = paper.data() as Map<String, dynamic>;
                  final bool isPaperPremium = paperData['isPremium'] ?? false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: AnimatedPaperCard(
                      title: paperData['name'] ?? paperData['title'] ?? paper.id.toUpperCase(),
                      paperId: paper.id,
                      categoryId: categoryId,
                      isPaperPremium: isPaperPremium,
                      isUserPremium: isUserPremium,
                      onNavigate: onNavigate,
                    ),
                  );
                },
              );
            },
          ),
        );
      }
    );
  }
}

class AnimatedPaperCard extends StatefulWidget {
  final String title;
  final String paperId;
  final String categoryId;
  final bool isPaperPremium;
  final bool isUserPremium;
  final Function(String) onNavigate;

  const AnimatedPaperCard({
    super.key,
    required this.title,
    required this.paperId,
    required this.categoryId,
    required this.isPaperPremium,
    required this.isUserPremium,
    required this.onNavigate,
  });

  @override
  State<AnimatedPaperCard> createState() => _AnimatedPaperCardState();
}

class _AnimatedPaperCardState extends State<AnimatedPaperCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: _isHovered ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
          border: Border.all(
            color: _isHovered ? const Color(0xFF38BDF8).withOpacity(0.5) : Colors.white10
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Paper eka click kalama kelinma QuizScreen ekata yanawa. Limit eka QuizScreen eke balanawa.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MainBackgroundWrapper(
                  child: QuizScreen(
                    categoryId: widget.categoryId, 
                    paperId: widget.paperId,
                    isUserPremium: widget.isUserPremium, 
                    isPaperPremium: widget.isPaperPremium, // Paper status eka pass karanawa
                    onNavigate: widget.onNavigate, 
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isPaperPremium ? Colors.amber.withOpacity(0.1) : const Color(0xFF38BDF8).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isPaperPremium ? Icons.workspace_premium : Icons.description, 
                    color: widget.isPaperPremium ? Colors.amber : const Color(0xFF38BDF8),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    widget.title, 
                    style: const TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white
                    )
                  )
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  transform: Matrix4.translationValues(_isHovered ? 5 : 0, 0, 0),
                  child: const Icon(
                    Icons.play_circle_fill, 
                    color: Color(0xFF38BDF8), 
                    size: 24
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}