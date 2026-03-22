import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/quiz_provider.dart';
import 'result_screen.dart';
import '../utils/app_constants.dart';
import '../main.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String paperId;
  final bool isUserPremium;
  final bool isPaperPremium;
  final Function(String) onNavigate;

  const QuizScreen({
    super.key, 
    required this.categoryId, 
    required this.paperId,
    required this.isUserPremium,
    required this.isPaperPremium,
    required this.onNavigate,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadQuestions(widget.categoryId, widget.paperId);
    });
  }

  // 1. ප්‍රශ්න අංකය (int questionNumber) argument එකක් ලෙස මෙතැනට ලබා දුන්නා
  void _showReportDialog(String questionText, int questionNumber) {
    final TextEditingController reportController = TextEditingController(text: "ප්‍රශ්නයේ පිළිතුර වැරදියි");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Report an Issue", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ප්‍රශ්නයේ ඇති ගැටලුව සඳහන් කරන්න:", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(
              controller: reportController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                hintText: "ගැටලුව මෙතැන ලියන්න...",
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              try {
                // 2. 'questionNumber' කියන field එක Firestore එකට එකතු කළා
                await FirebaseFirestore.instance.collection('question_reports').add({
                  'questionNumber': questionNumber, 
                  'question': questionText,
                  'paperId': widget.paperId,
                  'categoryId': widget.categoryId,
                  'reportMessage': reportController.text,
                  'reportedAt': FieldValue.serverTimestamp(),
                });

                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("ඔබේ වාර්තාව අප වෙත ලැබුණි. ස්තූතියි!")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("දෝෂයක් සිදු විය: $e")),
                );
              }
            },
            child: const Text("Submit Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPremiumLimitDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.workspace_premium, color: Colors.amber),
            SizedBox(width: 10),
            Text("Premium Feature", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          "මෙම ප්‍රශ්න පත්‍රයේ නොමිලේ ලබාදෙන ප්‍රශ්න ${AppConstants.freeQuestionLimit} අවසන්. සම්පූර්ණ ප්‍රශ්න පත්‍රයම කිරීමට Premium ලබාගන්න.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              Navigator.pop(context); 
            },
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8)),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
              widget.onNavigate("Premium"); 
            },
            child: const Text("Upgrade Now", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Consumer<QuizProvider>(
          builder: (context, quiz, _) => Container(
            height: 10, width: 130, 
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: quiz.questions.isEmpty ? 0 : (quiz.currentIndex + 1) / quiz.questions.length,
              child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent]), borderRadius: BorderRadius.circular(10))),
            ),
          ),
        ),
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quiz, _) {
              if (quiz.questions.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.outlined_flag, color: Colors.redAccent, size: 24),
                // 3. මෙතැනදී 'quiz.currentIndex + 1' ලෙස පවතින ප්‍රශ්න අංකය ලබා දුන්නා
                onPressed: () => _showReportDialog(
                  quiz.questions[quiz.currentIndex].questionText,
                  quiz.currentIndex + 1,
                ),
              );
            }
          ),
          Consumer<QuizProvider>(
            builder: (context, quiz, _) => Padding(
              padding: const EdgeInsets.only(right: 15),
              child: CircularPercentIndicator(
                radius: 20.0, lineWidth: 3.5, percent: quiz.timerPercent,
                center: Text("${quiz.secondsRemaining}", style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                progressColor: quiz.secondsRemaining < 10 ? Colors.redAccent : const Color(0xFF38BDF8),
                backgroundColor: Colors.white10, circularStrokeCap: CircularStrokeCap.round,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
          if (quizProvider.questions.isEmpty) return const Center(child: Text("No Questions Available!", style: TextStyle(color: Colors.white)));

          final q = quizProvider.questions[quizProvider.currentIndex];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15),
                Text("Question ${quizProvider.currentIndex + 1}/${quizProvider.questions.length}", style: const TextStyle(color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 10),
                Text(q.questionText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 15), child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(q.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.contain))),
                
                const SizedBox(height: 25),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: q.options.length,
                          itemBuilder: (context, index) {
                            bool isSelected = quizProvider.selectedAnswerIndex == index;
                            bool isCorrect = q.correctAnswerIndex == index;
                            
                            Color borderColor = Colors.white10;
                            Color cardColor = Colors.white.withOpacity(0.05);
                            IconData iconData = Icons.circle_outlined;
                            Color iconColor = Colors.white10;

                            if (quizProvider.isAnswerChecked) {
                              if (isCorrect) {
                                borderColor = Colors.greenAccent;
                                cardColor = Colors.green.withOpacity(0.2);
                                iconData = Icons.check_circle;
                                iconColor = Colors.greenAccent;
                              } else if (isSelected) {
                                borderColor = Colors.redAccent;
                                cardColor = Colors.red.withOpacity(0.2);
                                iconData = Icons.cancel;
                                iconColor = Colors.redAccent;
                              }
                            } else if (isSelected) {
                              borderColor = const Color(0xFF38BDF8);
                              cardColor = const Color(0xFF38BDF8).withOpacity(0.2);
                              iconData = Icons.check_circle;
                              iconColor = const Color(0xFF38BDF8);
                            }

                            return GestureDetector(
                              onTap: quizProvider.isAnswerChecked ? null : () => quizProvider.selectAnswer(index),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12), 
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor, 
                                  borderRadius: BorderRadius.circular(15), 
                                  border: Border.all(color: borderColor)
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                                  children: [
                                    Expanded(
                                      child: Text(
                                        q.options[index], 
                                        style: const TextStyle(color: Colors.white, fontSize: 16)
                                      )
                                    ), 
                                    Icon(iconData, color: iconColor, size: 20)
                                  ]
                                ),
                              ),
                            );
                          },
                        ),
                        
                        if (quizProvider.isAnswerChecked && q.explanation != null && q.explanation!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 10, bottom: 20),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lightbulb_outline, color: Color(0xFF10B981), size: 20),
                                    SizedBox(width: 10),
                                    Text("Explanation", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(q.explanation!, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "ප්‍රශ්නයේ ගැටලුවක් ඇත්නම් ",
                        style: TextStyle(color: Colors.white24, fontSize: 10.5),
                      ),
                      const Icon(Icons.outlined_flag, color: Colors.redAccent, size: 14),
                      const Text(
                        " මගින් report කළ හැක",
                        style: TextStyle(color: Colors.white24, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: quizProvider.selectedAnswerIndex == null ? null : () {
                       if (!quizProvider.isAnswerChecked) {
                         quizProvider.checkAnswer();
                       } else {
                         if (widget.isPaperPremium && !widget.isUserPremium && quizProvider.currentIndex == (AppConstants.freeQuestionLimit - 1) && quizProvider.questions.length > AppConstants.freeQuestionLimit) {
                           _showPremiumLimitDialog();
                         } else if (quizProvider.currentIndex == quizProvider.questions.length - 1) {
                           Navigator.pushReplacement(
                             context, 
                             MaterialPageRoute(
                               builder: (context) => MainBackgroundWrapper(
                                 child: ResultScreen(
                                   score: quizProvider.score, 
                                   totalQuestions: quizProvider.questions.length, 
                                   categoryId: widget.categoryId, 
                                   paperId: widget.paperId,
                                   isUserPremium: widget.isUserPremium,
                                   isPaperPremium: widget.isPaperPremium,
                                   onNavigate: widget.onNavigate,
                                 )
                               )
                             )
                           );
                         } else {
                           quizProvider.nextQuestion();
                         }
                       }
                    },
                    child: Text(!quizProvider.isAnswerChecked ? "Check Answer" : "Next", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                ),
                const SizedBox(height: 25),
              ],
            ),
          );
        },
      ),
    );
  }
}