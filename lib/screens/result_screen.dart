import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; 
import 'home_screen.dart';
import 'quiz_screen.dart';
import '../main.dart'; 

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryId;
  final String paperId;
  final bool isUserPremium;
  final bool isPaperPremium;
  final Function(String) onNavigate;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryId,
    required this.paperId,
    required this.isUserPremium,
    required this.isPaperPremium,
    required this.onNavigate,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isFirstAttempt = false; 
  bool _alreadyRated = false; // කලින් Rate කරලාද කියලා බලන්න
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveScoreToDatabase(); 
  }

  // XP සහ ලකුණු Save කිරීමේ Logic එක (Stable)
  Future<void> _saveScoreToDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final paperRef = userRef.collection('completed_papers').doc(widget.paperId);

      final paperDoc = await paperRef.get();

      if (!paperDoc.exists) {
        setState(() { 
          _isFirstAttempt = true; 
          _alreadyRated = false;
        });

        if (widget.score > 0) {
          await paperRef.set({
            'score': widget.score,
            'completedAt': Timestamp.now(),
            'isRated': false, // මුල් වතාවේදී false ලෙස Save කරයි
          });

          await userRef.set({
            'email': user.email,
            'totalScore': FieldValue.increment(widget.score), 
            'lastActive': Timestamp.now(),
          }, SetOptions(merge: true));
        }
      } else {
        setState(() { 
          _isFirstAttempt = false; 
          // Firestore එකෙන් කලින් Rate කරලා තියෙනවාද කියලා පරීක්ෂා කරයි
          _alreadyRated = paperDoc.data()?['isRated'] ?? false;
        });
      }
    }
    setState(() { _isLoading = false; });
  }

  // ⭐️ බොත්තම් එබූ විට ක්‍රියාත්මක වන Logic එක
  void _handleNavigation(BuildContext context, Widget destination) {
    // Rate කරලා නැති පේපර් එකක් නම් පමණක් Dialog එක පෙන්වයි
    if (!_alreadyRated) {
      _showRatingDialog(context, destination);
    } else {
      // කලින් Rate කර ඇත්නම් කෙලින්ම අදාළ Screen එකට යයි
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: destination)),
        (route) => false,
      );
    }
  }

  void _showRatingDialog(BuildContext context, Widget nextScreen) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _AnimatedRatingDialog(
        categoryId: widget.categoryId,
        paperId: widget.paperId,
        nextScreen: nextScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxScore = widget.totalQuestions * 10;
    final double percentage = maxScore == 0 ? 0.0 : widget.score / maxScore;
    
    String feedbackMessage;
    Color progressColor;
    
    if (percentage >= 0.8) {
      feedbackMessage = "Excellent Work! 🏆";
      progressColor = Colors.greenAccent;
    } else if (percentage >= 0.5) {
      feedbackMessage = "Good Job! 👍";
      progressColor = Colors.orangeAccent;
    } else {
      feedbackMessage = "Keep Practicing! 💪";
      progressColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text("Quiz Results"),
        automaticallyImplyLeading: false, 
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white.withValues(alpha: 0.95), 
                elevation: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(feedbackMessage, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF001A33))),
                      const SizedBox(height: 30),
                      CircularPercentIndicator(
                        radius: 80.0,
                        lineWidth: 12.0,
                        animation: true,
                        animationDuration: 1000,
                        percent: percentage,
                        center: Text(
                          "${(percentage * 100).toInt()}%",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 35.0, color: Color(0xFF001A33)),
                        ),
                        circularStrokeCap: CircularStrokeCap.round,
                        progressColor: progressColor,
                        backgroundColor: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 20),
                      Text("Your Score: ${widget.score} / $maxScore", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        decoration: BoxDecoration(
                          color: _isFirstAttempt ? const Color(0xFF10B981).withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isFirstAttempt ? const Color(0xFF10B981).withValues(alpha: 0.5) : Colors.orange.withValues(alpha: 0.5),
                            width: 1.5,
                          )
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isFirstAttempt 
                                  ? "✨ ${widget.score} XP added to your Leaderboard!" 
                                  : "🔄 Practice Run: You have already completed this paper, so these points won't be added to the Leaderboard.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _isFirstAttempt ? Colors.green.shade800 : Colors.deepOrange.shade800, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (_isFirstAttempt) ...[
                              const SizedBox(height: 5),
                              Text(
                                "(10 XP per correct answer)",
                                style: TextStyle(
                                  color: Colors.green.shade900.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent, 
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              // Retry Click කළ විට
                              _handleNavigation(context, QuizScreen(
                                categoryId: widget.categoryId, 
                                paperId: widget.paperId,
                                isUserPremium: widget.isUserPremium, 
                                isPaperPremium: widget.isPaperPremium,
                                onNavigate: widget.onNavigate,
                              ));
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text("Retry", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005493), 
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              // Home Click කළ විට
                              _handleNavigation(context, const HomeScreen());
                            },
                            icon: const Icon(Icons.home, color: Colors.white),
                            label: const Text("Home", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

// ⭐️ Submit බොත්තම සහිත Animated Gradient Rating Dialog එක
class _AnimatedRatingDialog extends StatefulWidget {
  final String categoryId;
  final String paperId;
  final Widget nextScreen;

  const _AnimatedRatingDialog({required this.categoryId, required this.paperId, required this.nextScreen});

  @override
  State<_AnimatedRatingDialog> createState() => _AnimatedRatingDialogState();
}

class _AnimatedRatingDialogState extends State<_AnimatedRatingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _userRating = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: const [Color(0xFF001A33), Color(0xFF005493), Color(0xFF001A33)],
                begin: Alignment(-3.0 + (_controller.value * 6), -1.0),
                end: Alignment(3.0 + (_controller.value * 6), 1.0),
              ),
            ),
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Rate this Paper",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "ඔබේ තරු සලකුණ ලබා දී අපව දියුණු කිරීමට සහය වන්න.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 25),
                RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 42,
                  unratedColor: Colors.white24,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemBuilder: (context, _) => const Icon(Icons.star_rounded, color: Colors.amber),
                  onRatingUpdate: (rating) {
                    setState(() { _userRating = rating; });
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _userRating > 0 ? Colors.amber : Colors.grey.shade400,
                      foregroundColor: const Color(0xFF001A33),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _userRating == 0 ? null : () async {
                      // Firestore එක Update කිරීම
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final batch = FirebaseFirestore.instance.batch();
                        
                        final userRef = FirebaseFirestore.instance
                            .collection('users').doc(user.uid)
                            .collection('completed_papers').doc(widget.paperId);
                        batch.update(userRef, {
                          'isRated': true, // දෙපාරක් Rate කිරීම වැළැක්වීමට
                          'ratingValue': _userRating,
                        });

                        final paperRef = FirebaseFirestore.instance
                            .collection('categories').doc(widget.categoryId)
                            .collection('papers').doc(widget.paperId);
                        batch.set(paperRef, {
                          'totalRating': FieldValue.increment(_userRating),
                          'ratingCount': FieldValue.increment(1),
                        }, SetOptions(merge: true));

                        await batch.commit();
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context); // Dialog වසන්න
                      // ඉන්පසු අදාළ Screen එකට (Home හෝ Retry) යන්න
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: widget.nextScreen)),
                        (route) => false,
                      );
                    },
                    child: const Text("Submit Rating", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        );
      },
    );
  }
}