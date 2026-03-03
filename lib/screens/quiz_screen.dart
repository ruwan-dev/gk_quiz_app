import 'package:flutter/material.dart';
import '../models/question_model.dart';
import '../services/database_service.dart'; // අලුත් Service එක import කරන්න

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentIndex = 0;
  int score = 0;
  int? selectedAnswerIndex;
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Government Exam Quiz")),
      // StreamBuilder එකෙන් Firebase එකේ දත්ත එනකන් බලාගෙන ඉන්නවා
      body: StreamBuilder<List<Question>>(
        stream: _dbService.getQuestions(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Error loading questions"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final questions = snapshot.data ?? [];
          if (questions.isEmpty) return const Center(child: Text("ප්‍රශ්න කිසිවක් හමු නොවීය."));

          final currentQuestion = questions[currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(value: (currentIndex + 1) / questions.length),
                const SizedBox(height: 30),
                // ප්‍රශ්නය පෙන්වන තැන
                Text(currentQuestion.questionText, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 20),
                // උත්තර ලැයිස්තුව
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(currentQuestion.options[index]),
                        leading: Radio<int>(
                          value: index,
                          groupValue: selectedAnswerIndex,
                          onChanged: (val) => setState(() => selectedAnswerIndex = val),
                        ),
                      );
                    },
                  ),
                ),
                // Next Button logic එක මෙතනට...
                ElevatedButton(
                  onPressed: selectedAnswerIndex != null ? () {
                    if (selectedAnswerIndex == currentQuestion.correctAnswerIndex) score++;
                    if (currentIndex < questions.length - 1) {
                      setState(() { currentIndex++; selectedAnswerIndex = null; });
                    } else {
                       // Result dialog එක පෙන්වන්න (කලින් කේතයම පාවිච්චි කරන්න)
                    }
                  } : null,
                  child: const Text("Next"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}