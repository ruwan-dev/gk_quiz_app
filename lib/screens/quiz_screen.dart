import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/quiz_provider.dart';

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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(widget.paperId.toUpperCase()),
        actions: [
          Consumer<QuizProvider>(
            builder: (context, quizProvider, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 15),
                child: CircularPercentIndicator(
                  radius: 20.0,
                  lineWidth: 3.5,
                  percent: quizProvider.timerPercent,
                  center: Text("${quizProvider.secondsRemaining}", style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                  progressColor: quizProvider.secondsRemaining < 10 ? Colors.redAccent : Colors.greenAccent,
                  backgroundColor: Colors.white24,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) return const Center(child: CircularProgressIndicator(color: Colors.white));
          if (quizProvider.questions.isEmpty) return const Center(child: Text("No questions available", style: TextStyle(color: Colors.white)));

          final currentQuestion = quizProvider.questions[quizProvider.currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: (quizProvider.currentIndex + 1) / quizProvider.questions.length, color: Colors.white, backgroundColor: Colors.white12),
                const SizedBox(height: 10),
                Text(
                  "Question ${quizProvider.currentIndex + 1} / ${quizProvider.questions.length}",
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Text(currentQuestion.questionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      Color buttonColor = Colors.white;
                      if (quizProvider.isAnswerChecked) {
                        if (index == currentQuestion.correctAnswerIndex) buttonColor = Colors.green.shade400;
                        else if (index == quizProvider.selectedAnswerIndex) buttonColor = Colors.red.shade400;
                      } else if (index == quizProvider.selectedAnswerIndex) buttonColor = Colors.blue.shade100;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: buttonColor, foregroundColor: Colors.black87),
                          onPressed: () => quizProvider.selectAnswer(index),
                          child: Text(currentQuestion.options[index], textAlign: TextAlign.center),
                        ),
                      );
                    },
                  ),
                ),
                if (quizProvider.isAnswerChecked)
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    child: Text("💡 Explanation: ${currentQuestion.explanation}", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13)),
                  ),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.arrow_circle_left, size: 45, color: Colors.white70), onPressed: quizProvider.currentIndex == 0 ? null : () => quizProvider.prevQuestion()),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: quizProvider.isAnswerChecked 
                          ? const SizedBox.shrink() 
                          : ElevatedButton(
                              onPressed: quizProvider.selectedAnswerIndex == null ? null : () => quizProvider.checkAnswer(),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                              child: const Text("Check Answer"),
                            ),
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.arrow_circle_right, size: 45, color: Colors.white), onPressed: !quizProvider.isAnswerChecked ? null : () => quizProvider.nextQuestion()),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}