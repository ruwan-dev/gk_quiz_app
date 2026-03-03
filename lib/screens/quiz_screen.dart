import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'admin_panel.dart'; // Admin Panel එක මෙතනට import කරන්න

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(context, listen: false).loadQuestions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GK Quiz App"), 
        backgroundColor: Colors.blueAccent,
        // මෙන්න මෙතනට මම Admin Panel එකට යන button එක ආයෙත් දැම්මා
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminPanel()),
              );
            },
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) return const Center(child: CircularProgressIndicator());
          if (quizProvider.questions.isEmpty) return const Center(child: Text("ප්‍රශ්න කිසිවක් හමු නොවීය."));

          final currentQuestion = quizProvider.questions[quizProvider.currentIndex];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress Bar එක
                LinearProgressIndicator(
                  value: (quizProvider.currentIndex + 1) / quizProvider.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 20),
                Text(
                  "ප්‍රශ්නය ${quizProvider.currentIndex + 1} / ${quizProvider.questions.length}", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 15),
                Text(currentQuestion.questionText, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 25),

                // පිළිතුරු (Options) ලැයිස්තුව
                ...List.generate(currentQuestion.options.length, (index) {
                  Color buttonColor = Colors.white;
                  
                  if (quizProvider.isAnswerChecked) {
                    // නිවැරදි පිළිතුර සැමවිටම කොළ පාටින්
                    if (index == currentQuestion.correctAnswerIndex) {
                      buttonColor = Colors.green.shade400;
                    } 
                    // වැරදි එකක් තෝරා ඇත්නම් එය රතු පාටින්
                    else if (index == quizProvider.selectedAnswerIndex) {
                      buttonColor = Colors.red.shade400;
                    }
                  } else {
                    // තවම චෙක් කර නැති විට තෝරාගත් එක නිල් පාටින්
                    if (index == quizProvider.selectedAnswerIndex) {
                      buttonColor = Colors.blue.shade100;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.black87,
                        side: BorderSide(
                          color: quizProvider.selectedAnswerIndex == index ? Colors.blue : Colors.grey.shade300
                        ),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => quizProvider.selectAnswer(index),
                      child: Text(currentQuestion.options[index], style: const TextStyle(fontSize: 17)),
                    ),
                  );
                }),

                const SizedBox(height: 20),
                
                // "Check Answer" Button
                if (!quizProvider.isAnswerChecked)
                  ElevatedButton(
                    onPressed: quizProvider.selectedAnswerIndex == null ? null : () => quizProvider.checkAnswer(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Check Answer", style: TextStyle(fontSize: 18)),
                  ),

                // Explanation (උත්තරේ චෙක් කළාට පස්සේ පෙන්වයි)
                if (quizProvider.isAnswerChecked)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100, 
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      "💡 විස්තරය: ${currentQuestion.explanation}", 
                      style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15)
                    ),
                  ),

                const Spacer(),

                // Navigation (Back & Next)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: quizProvider.currentIndex == 0 ? null : () => quizProvider.prevQuestion(),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Back"),
                    ),
                    ElevatedButton.icon(
                      onPressed: !quizProvider.isAnswerChecked ? null : () => quizProvider.nextQuestion(),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Next"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, 
                        foregroundColor: Colors.white
                      ),
                    ),
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