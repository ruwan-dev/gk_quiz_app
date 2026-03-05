import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: Consumer<QuizProvider>(
          builder: (context, quiz, _) => Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: quiz.questions.isEmpty ? 0 : (quiz.currentIndex + 1) / quiz.questions.length,
              child: Container(decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Colors.pinkAccent, Colors.purpleAccent]),
                borderRadius: BorderRadius.circular(10),
              )),
            ),
          ),
        ),
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          if (quizProvider.questions.isEmpty) return const Center(child: Text("No Questions!", style: TextStyle(color: Colors.white)));

          final q = quizProvider.questions[quizProvider.currentIndex];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text("Question ${quizProvider.currentIndex + 1}/${quizProvider.questions.length}", 
                  style: const TextStyle(color: Colors.white60, fontSize: 16)),
                const SizedBox(height: 20),
                Text(q.questionText, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                
                if (q.imageUrl != null && q.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.network(q.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover)),
                  ),

                const SizedBox(height: 30),
                Expanded(
                  child: ListView.builder(
                    itemCount: q.options.length,
                    itemBuilder: (context, index) {
                      bool isSelected = quizProvider.selectedAnswerIndex == index;
                      return GestureDetector(
                        onTap: () => quizProvider.selectAnswer(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(q.options[index], style: const TextStyle(color: Colors.white, fontSize: 16)),
                              Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? Colors.blueAccent : Colors.white24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: quizProvider.selectedAnswerIndex == null ? null : () {
                       if (quizProvider.currentIndex == quizProvider.questions.length - 1) {
                         Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: ResultScreen(score: quizProvider.score, totalQuestions: quizProvider.questions.length, categoryId: widget.categoryId, paperId: widget.paperId))));
                       } else {
                         quizProvider.nextQuestion();
                       }
                    },
                    child: const Text("Next", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }
}