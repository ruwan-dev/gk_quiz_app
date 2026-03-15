import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import '../main.dart'; 

class ResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final String categoryId;
  final String paperId;

  // Premium Limit එකට අවශ්‍ය parameters
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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _saveScoreToDatabase(); 
  }

  // Leaderboard එකට ලකුණු එකතු කිරීමේ Logic එක
  Future<void> _saveScoreToDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final paperRef = userRef.collection('completed_papers').doc(widget.paperId);

      final paperDoc = await paperRef.get();

      if (!paperDoc.exists) {
        setState(() { _isFirstAttempt = true; });

        if (widget.score > 0) {
          await paperRef.set({
            'score': widget.score,
            'completedAt': Timestamp.now(),
          });

          await userRef.set({
            'email': user.email,
            'totalScore': FieldValue.increment(widget.score), 
            'lastActive': Timestamp.now(),
          }, SetOptions(merge: true));
        }
      } else {
        setState(() { _isFirstAttempt = false; });
      }
    }
    setState(() { _isLoading = false; });
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
                      
                      Text("Your Score: ${widget.score} / $maxScore", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      
                      const SizedBox(height: 15),
                      
                      // 🚀 XP විස්තරය සහ ඉංග්‍රීසි පණිවිඩය පෙන්වන කොටස
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
                                  color: Colors.green.shade900.withOpacity(0.7),
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
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: QuizScreen(
                                  categoryId: widget.categoryId, 
                                  paperId: widget.paperId,
                                  isUserPremium: widget.isUserPremium, 
                                  isPaperPremium: widget.isPaperPremium,
                                  onNavigate: widget.onNavigate,
                                ))),
                              );
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
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const MainBackgroundWrapper(child: HomeScreen())),
                                (route) => false,
                              );
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