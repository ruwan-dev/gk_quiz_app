import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers ටික
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = 
      List.generate(4, (index) => TextEditingController());
  final TextEditingController _explanationController = TextEditingController();
  
  int _correctIndex = 0; // නිවැරදි උත්තරයේ අංකය (0, 1, 2, 3)
  bool _isSaving = false;

  // Firestore එකට Data යවන Function එක
  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      try {
        await FirebaseFirestore.instance.collection('quizzes').add({
          'questionText': _questionController.text.trim(),
          'options': _optionControllers.map((c) => c.text.trim()).toList(),
          'correctAnswerIndex': _correctIndex,
          'explanation': _explanationController.text.trim(),
          'createdAt': Timestamp.now(),
        });

        // සාර්ථක වුණොත් Fields හිස් කරන්න
        _questionController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
        _explanationController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ ප්‍රශ්නය සාර්ථකව ඇතුළත් කළා!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ දෝෂයක්: $e")),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel - Add Question")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ප්‍රශ්නය
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: "ප්‍රශ්නය (Question Text)", border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "ප්‍රශ්නය ඇතුළත් කරන්න" : null,
              ),
              const SizedBox(height: 20),

              // උත්තර 4
              const Text("පිළිතුරු (Options):", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextFormField(
                  controller: _optionControllers[index],
                  decoration: InputDecoration(
                    labelText: "Option ${index + 1}",
                    border: const OutlineInputBorder(),
                    prefixIcon: Radio<int>(
                      value: index,
                      groupValue: _correctIndex,
                      onChanged: (val) => setState(() => _correctIndex = val!),
                    ),
                  ),
                  validator: (v) => v!.isEmpty ? "පිළිතුරක් ඇතුළත් කරන්න" : null,
                ),
              )),

              const SizedBox(height: 10),
              Text("💡 නිවැරදි පිළිතුර තෝරන්න (Radio Button එකෙන්)", 
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              const SizedBox(height: 20),

              // විස්තරය
              TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(labelText: "විස්තරය (Explanation)", border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? "විස්තරය ඇතුළත් කරන්න" : null,
              ),
              const SizedBox(height: 30),

              // Save Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Colors.blue, foregroundColor: Colors.white),
                onPressed: _isSaving ? null : _saveQuestion,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save to Firebase", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}