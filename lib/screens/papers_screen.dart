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
  final Function(String) onNavigate; // 🚀 Tab මාරු කරන function එක

  const PapersScreen({
    super.key, 
    required this.categoryId, 
    required this.categoryName,
    required this.onNavigate, // Constructor එකට එක් කළා
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
              
              final allDocs = snapshot.data!.docs;
              
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !(data.containsKey('isVisible') && data['isVisible'] == false);
              }).toList();

              if (docs.isEmpty) {
                return const Center(
                  child: Text("No papers found.", style: TextStyle(color: Colors.white, fontSize: 16)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final paper = docs[index];
                  final paperData = paper.data() as Map<String, dynamic>;
                  
                  final String paperDisplayName = (paperData['title'] != null && paperData['title'].toString().isNotEmpty) 
                      ? paperData['title'] 
                      : paper.id.replaceAll('_', ' ').toUpperCase();

                  final bool isPaperPremium = paperData.containsKey('isPremium') ? paperData['isPremium'] : false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: AnimatedPaperCard(
                      title: paperDisplayName,
                      paperId: paper.id,
                      categoryId: categoryId,
                      isPaperPremium: isPaperPremium,
                      isUserPremium: isUserPremium,
                      onNavigate: onNavigate, // 🚀 Card එකට Pass කළා
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
  final Function(String) onNavigate; // 🚀 Tab Navigate Function

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

class _AnimatedPaperCardState extends State<AnimatedPaperCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isLocked = widget.isPaperPremium && !widget.isUserPremium;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _isHovered && !isLocked ? GradientBorderPainter(
              angle: _controller.value * 2 * math.pi,
              strokeWidth: 2.5,
              radius: 20,
              gradientColors: [
                const Color(0xFF38BDF8),
                const Color(0xFFFF4757),
                const Color(0xFF38BDF8),
              ],
            ) : null,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _isHovered && !isLocked ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: _isHovered && !isLocked ? Colors.transparent : Colors.white12,
              width: 1.0,
            ),
            boxShadow: [
              if (_isHovered && !isLocked)
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (isLocked) {
                  // 🚀 Popup වෙනුවට Premium Tab එකට Navigate කරයි
                  Navigator.pop(context); // Papers ලිස්ට් එක Close කරයි
                  widget.onNavigate("Premium"); // Premium Tab එක පෙන්වයි
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainBackgroundWrapper(
                        child: QuizScreen(categoryId: widget.categoryId, paperId: widget.paperId),
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.isPaperPremium 
                          ? Colors.amber.withOpacity(0.1) 
                          : const Color(0xFF38BDF8).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isPaperPremium ? Icons.workspace_premium : Icons.description, 
                        color: widget.isPaperPremium ? Colors.amber : const Color(0xFF38BDF8), 
                        size: 28
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: isLocked ? Colors.white54 : Colors.white
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isLocked ? "Premium Members Only" : "Tap to start the quiz",
                            style: TextStyle(
                              color: isLocked ? Colors.amber.withOpacity(0.8) : Colors.white38, 
                              fontSize: 13
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues((_isHovered && !isLocked) ? 5 : 0, 0, 0),
                      child: Icon(
                        isLocked ? Icons.lock : Icons.play_circle_fill, 
                        color: isLocked ? Colors.white38 : const Color(0xFF38BDF8), 
                        size: 32
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final double angle;
  final double strokeWidth;
  final double radius;
  final List<Color> gradientColors;

  GradientBorderPainter({
    required this.angle,
    required this.strokeWidth,
    required this.radius,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = SweepGradient(
        colors: gradientColors,
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) => 
      oldDelegate.angle != angle;
}