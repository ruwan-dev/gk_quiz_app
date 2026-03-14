class AppPrompts {

  static const String generalQuizPrompt = """
Please generate a JSON array of 50 multiple-choice questions for a General Knowledge quiz targeting Sri Lankan government competitive exams (like SLAS, Registrar Service, or Grama Niladhari exams).

Topic: [ENTER TOPIC HERE]
Language: High-quality Sinhala (සිංහල)

Critical Requirement: Ensure all questions and answers are based strictly on factual truth. Only provide 100% accurate information.

Answer Distribution Requirement: Randomly distribute the position of the correct answer across the options.

Strict JSON Schema:
[
  {
    "question": "The question text in Sinhala",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctAnswerIndex": 0, 
    "explanation": "A brief explanation confirming the factual accuracy in Sinhala"
  }
]
Instructions:
Double-check that the correctAnswerIndex is 100% accurate for each question.
The explanation field must cite the factual basis briefly.
Avoid duplicate questions.
Output only the JSON array, no conversational text.
""";


  static const String pdfQuizPrompt = """
I have uploaded a PDF document. Please read and analyze its content to generate a JSON array of 50 multiple-choice questions for a General Knowledge quiz (Sri Lankan government exams).

Language: High-quality Sinhala (සිංහල)

Strict Content Rule: Base all questions and answers ONLY on the factual information provided in the attached PDF.

Answer Distribution Requirement: Randomly distribute the correct answer index (0-3).

Strict JSON Schema:
[
  {
    "question": "The question text in Sinhala",
    "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
    "correctAnswerIndex": 0, 
    "explanation": "A brief explanation in Sinhala, citing the relevant point from the PDF"
  }
]

Instructions:
Double-check that the correctAnswerIndex is 100% accurate for each question.
The explanation field must cite the factual basis briefly.
Avoid duplicate questions.
Output only the JSON array, no conversational text.
""";
}