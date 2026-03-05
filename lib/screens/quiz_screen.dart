import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart'; // ⏱️ Timer එකට අවශ්‍යයි
import '../providers/quiz_provider.dart';
import 'result_screen.dart';
import '../main.dart';

class QuizScreen extends StatefulWidget {
  final String categoryId;
  final String paperId;

  const QuizScreen({super.key, required this.categoryId, required this.paperId});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // අපේ අඳුරු පසුබිම
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white), 
          onPressed: () => Navigator.pop(context)
        ),
        title: Consumer<QuizProvider>(
          builder: (context, quiz, _) => Container(
            height: 10,
            width: 160,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: quiz.questions.isEmpty ? 0 : (quiz.currentIndex + 1) / quiz.questions.length,
              child: Container(decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent]), // Pink-Purple Progress
                borderRadius: BorderRadius.circular(10),
              )),
            ),
          ),
        ),
        actions: [
          // ⏱️ Timer එක AppBar එකේ දකුණු පැත්තට එකතු කළා
          Consumer<QuizProvider>(
            builder: (context, quiz, _) => Padding(
              padding: const EdgeInsets.only(right: 15),
              child: CircularPercentIndicator(
                radius: 20.0,
                lineWidth: 3.5,
                percent: quiz.timerPercent,
                center: Text("${quiz.secondsRemaining}", 
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                progressColor: quiz.secondsRemaining < 10 ? Colors.redAccent : const Color(0xFF38BDF8), // තත්පර 10ට අඩු නම් රතු වෙනවා
                backgroundColor: Colors.white10,
                circularStrokeCap: CircularStrokeCap.round,
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
                Text("Question ${quizProvider.currentIndex + 1}/${quizProvider.questions.length}", 
                  style: const TextStyle(color: Colors.white38, fontSize: 14)),
                const SizedBox(height: 10),
                Text(q.questionText, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                
                // 🖼️ රූපයක් තිබේ නම් පමණක් පෙන්වන්න
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15), 
                      child: Image.network(q.imageUrl!, height: 160, width: double.infinity, fit: BoxFit.contain)
                    ),
                  ),

                const SizedBox(height: 25),
                
                // Options List
                Expanded(
                  child: ListView.builder(
                    itemCount: q.options.length,
                    itemBuilder: (context, index) {
                      bool isSelected = quizProvider.selectedAnswerIndex == index;
                      bool isCorrect = q.correctAnswerIndex == index;
                      
                      // පිළිතුර පරීක්ෂා කළ පසු වර්ණය වෙනස් කිරීම
                      Color cardColor = Colors.white.withOpacity(0.05);
                      Color borderColor = Colors.white10;

                      if (quizProvider.isAnswerChecked) {
                        if (isCorrect) {
                          cardColor = Colors.green.withOpacity(0.2);
                          borderColor = Colors.greenAccent;
                        } else if (isSelected) {
                          cardColor = Colors.red.withOpacity(0.2);
                          borderColor = Colors.redAccent;
                        }
                      } else if (isSelected) {
                        cardColor = const Color(0xFF38BDF8).withOpacity(0.2);
                        borderColor = const Color(0xFF38BDF8);
                      }

                      return GestureDetector(
                        onTap: quizProvider.isAnswerChecked ? null : () => quizProvider.selectAnswer(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(q.options[index], style: const TextStyle(color: Colors.white, fontSize: 16))),
                              Icon(
                                isSelected ? Icons.check_circle : Icons.circle_outlined, 
                                color: borderColor, size: 20
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 💡 Explanation (විස්තරය) - පිළිතුර පරීක්ෂා කළ පසු පමණක් දිස්වේ
                if (quizProvider.isAnswerChecked && q.explanation.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                            SizedBox(width: 8),
                            Text("Explanation", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(q.explanation, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),

                // පල්ලෙහා බටන් එක (Check Answer හෝ Next)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: quizProvider.selectedAnswerIndex == null ? null : () {
                       if (!quizProvider.isAnswerChecked) {
                         quizProvider.checkAnswer();
                       } else {
                         if (quizProvider.currentIndex == quizProvider.questions.length - 1) {
                           Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: ResultScreen(score: quizProvider.score, totalQuestions: quizProvider.questions.length, categoryId: widget.categoryId, paperId: widget.paperId))));
                         } else {
                           quizProvider.nextQuestion();
                         }
                       }
                    },
                    child: Text(
                      !quizProvider.isAnswerChecked ? "Check Answer" : "Next", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
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