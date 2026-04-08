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
  final List<Map<String, dynamic>> wrongAnswers;
  final Function(String) onNavigate;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.categoryId,
    required this.paperId,
    required this.isUserPremium,
    required this.isPaperPremium,
    required this.wrongAnswers,
    required this.onNavigate,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isFirstAttempt = false; 
  bool _alreadyRated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveScoreToDatabase(); 
  }

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
            'isRated': false,
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
          _alreadyRated = paperDoc.data()?['isRated'] ?? false;
        });
      }
    }
    setState(() { _isLoading = false; });
  }

  void _handleNavigation(BuildContext context, Widget destination) {
    if (!_alreadyRated) {
      _showRatingDialog(context, destination);
    } else {
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

  void _showReviewBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("වැරදුනු ප්‍රශ්න", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white), 
                    onPressed: () => Navigator.pop(context),
                  ),
                ]
              )
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: widget.wrongAnswers.length,
                itemBuilder: (context, index) {
                  final item = widget.wrongAnswers[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Q: ${item['questionText']}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.cancel, color: Colors.redAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text("ඔබේ පිළිතුර: ${item['selectedOption']}", style: const TextStyle(color: Colors.redAccent, fontSize: 15))),
                          ]
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text("නිවැරදි පිළිතුර: ${item['correctOption']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 15))),
                          ]
                        ),
                        if (item['explanation'] != null && item['explanation'].toString().isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.lightbulb_outline, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Expanded(child: Text(item['explanation'], style: const TextStyle(color: Colors.white70, fontSize: 14))),
                              ],
                            ),
                          )
                        ]
                      ]
                    )
                  );
                }
              )
            )
          ]
        )
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final int maxScore = widget.totalQuestions * 10;
    final double percentage = maxScore == 0 ? 0.0 : widget.score / maxScore;
    
    String feedbackMessage;
    Color progressColor;
    
    if (percentage >= 0.8) {
      feedbackMessage = "විශිෂ්ටයි! 🏆";
      progressColor = Colors.greenAccent;
    } else if (percentage >= 0.5) {
      feedbackMessage = "ඉතා හොඳයි! 👍";
      progressColor = Colors.orangeAccent;
    } else {
      feedbackMessage = "තවදුරටත් පුහුණු වන්න! 💪";
      progressColor = Colors.redAccent;
    }

    return Scaffold(
      backgroundColor: Colors.transparent, 
      appBar: AppBar(
        title: const Text("ප්‍රතිඵල"),
        automaticallyImplyLeading: false, 
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white.withOpacity(0.95), 
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
                      Text("ඔබේ ලකුණු: ${widget.score} / $maxScore", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 15),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                        decoration: BoxDecoration(
                          color: _isFirstAttempt ? const Color(0xFF10B981).withOpacity(0.15) : Colors.orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isFirstAttempt ? const Color(0xFF10B981).withOpacity(0.5) : Colors.orange.withOpacity(0.5),
                            width: 1.5,
                          )
                        ),
                        child: Column(
                          children: [
                            Text(
                              _isFirstAttempt 
                                  ? "✨ ඔබගේ Leaderboard එකට ${widget.score} XP එකතු විය!" 
                                  : "ඔබ මීට පෙර මෙම ප්‍රශ්න පත්‍රය කර ඇති බැවින්, මෙම ලකුණු Leaderboard එකට එකතු නොවේ.",
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
                                "(නිවැරදි පිළිතුරකට 10 XP බැගින්)",
                                style: TextStyle(
                                  color: Colors.green.shade900.withOpacity(0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      if (widget.wrongAnswers.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 25),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withOpacity(0.1),
                                foregroundColor: Colors.redAccent,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                                ),
                              ),
                              onPressed: () => _showReviewBottomSheet(context),
                              icon: const Icon(Icons.error_outline),
                              label: const Text("වැරදුනු ප්‍රශ්න බලන්න", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ),
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
                              _handleNavigation(context, QuizScreen(
                                categoryId: widget.categoryId, 
                                paperId: widget.paperId,
                                isUserPremium: widget.isUserPremium, 
                                isPaperPremium: widget.isPaperPremium,
                                onNavigate: widget.onNavigate,
                              ));
                            },
                            icon: const Icon(Icons.refresh, color: Colors.white),
                            label: const Text("නැවත කරන්න", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005493), 
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              _handleNavigation(context, const HomeScreen());
                            },
                            icon: const Icon(Icons.home, color: Colors.white),
                            label: const Text("මුල් පිටුව", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  "ප්‍රශ්න පත්‍රය Rate කරන්න",
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
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        try {
                          final userRef = FirebaseFirestore.instance
                              .collection('users').doc(user.uid)
                              .collection('completed_papers').doc(widget.paperId);
                          
                          await userRef.set({
                            'isRated': true,
                            'ratingValue': _userRating,
                          }, SetOptions(merge: true));

                          final paperRef = FirebaseFirestore.instance
                              .collection('categories').doc(widget.categoryId)
                              .collection('papers').doc(widget.paperId);
                          
                          await paperRef.set({
                            'totalRating': FieldValue.increment(_userRating),
                            'ratingCount': FieldValue.increment(1),
                          }, SetOptions(merge: true));
                        } catch (e) {
                          debugPrint("Rating save warning: $e");
                        }
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context); 
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: widget.nextScreen)),
                        (route) => false,
                      );
                    },
                    child: const Text("Submit කරන්න", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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