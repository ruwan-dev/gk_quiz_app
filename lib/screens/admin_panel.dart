import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _paperController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = 
      List.generate(4, (index) => TextEditingController());
  final TextEditingController _explanationController = TextEditingController();
  
  int _correctIndex = 0; 
  bool _isSaving = false;

  Future<void> _saveToFirestore() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final String catId = _categoryController.text.trim().toLowerCase();
      final String paperId = _paperController.text.trim().toLowerCase();

      try {
        await FirebaseFirestore.instance
            .collection('categories')
            .doc(catId)
            .collection('papers')
            .doc(paperId)
            .set({
              'lastUpdated': Timestamp.now(),
              'paperName': paperId.toUpperCase(),
            }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('categories')
            .doc(catId)
            .collection('papers')
            .doc(paperId)
            .collection('questions')
            .add({
              'questionText': _questionController.text.trim(),
              'options': _optionControllers.map((c) => c.text.trim()).toList(),
              'correctAnswerIndex': _correctIndex,
              'explanation': _explanationController.text.trim(),
              'createdAt': Timestamp.now(),
            });

        _questionController.clear();
        for (var c in _optionControllers) {
          c.clear();
        }
        _explanationController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Saved successfully!")), // ඉංග්‍රීසි කළා
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Error: $e")),
        );
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin - Add Question")), // ඉංග්‍රීසි කළා
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: "Category (gk/iq)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _paperController,
                      decoration: const InputDecoration(labelText: "Paper ID (paper_01)", border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(labelText: "Question Text", border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Enter question" : null,
              ),
              const SizedBox(height: 20),
              const Text("Options (Select the correct answer):", style: TextStyle(fontWeight: FontWeight.bold)),
              ...List.generate(4, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
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
                  validator: (v) => v!.isEmpty ? "Enter option" : null,
                ),
              )),
              const SizedBox(height: 20),
              TextFormField(
                controller: _explanationController,
                decoration: const InputDecoration(labelText: "Explanation", border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? "Enter explanation" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white
                ),
                onPressed: _isSaving ? null : _saveToFirestore,
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("Save to Firebase", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}