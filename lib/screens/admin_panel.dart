import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final TextEditingController _catNameController = TextEditingController();
  final TextEditingController _catIdController = TextEditingController();
  final TextEditingController _paperIdController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController _explanationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  int _correctAnswerIndex = 0; 
  String? _selectedCatId;
  String? _selectedPaperId;

  void _addCategory() async {
    if (_catNameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('categories').doc(_catIdController.text).set({
        'name': _catNameController.text, 'id': _catIdController.text, 'createdAt': Timestamp.now(),
      });
      _catNameController.clear(); _catIdController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Category Added!")));
    }
  }

  void _addQuestion() async {
    if (_selectedPaperId != null && _questionController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('categories').doc(_selectedCatId).collection('papers').doc(_selectedPaperId).collection('questions').add({
        'questionText': _questionController.text,
        'options': _optionControllers.map((c) => c.text).toList(),
        'correctAnswerIndex': _correctAnswerIndex,
        'explanation': _explanationController.text,
        'imageUrl': _imageUrlController.text,
        'createdAt': Timestamp.now(),
      });
      _questionController.clear(); _imageUrlController.clear();
      for (var c in _optionControllers) { c.clear(); }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Question Added!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _catNameController, decoration: const InputDecoration(labelText: "Category Name")),
            TextField(controller: _catIdController, decoration: const InputDecoration(labelText: "Category ID")),
            ElevatedButton(onPressed: _addCategory, child: const Text("Add Category")),
            const Divider(height: 50),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const CircularProgressIndicator();
                return DropdownButton<String>(
                  value: _selectedCatId,
                  hint: const Text("Select Category"),
                  items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
                  onChanged: (v) => setState(() { _selectedCatId = v; _selectedPaperId = null; }),
                );
              },
            ),
            if (_selectedCatId != null)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('categories').doc(_selectedCatId).collection('papers').snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  return DropdownButton<String>(
                    value: _selectedPaperId,
                    hint: const Text("Select Paper"),
                    items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['title']))).toList(),
                    onChanged: (v) => setState(() => _selectedPaperId = v),
                  );
                },
              ),
            TextField(controller: _questionController, decoration: const InputDecoration(labelText: "Question")),
            TextField(controller: _imageUrlController, decoration: const InputDecoration(labelText: "Image URL (Optional)")),
            ...List.generate(4, (i) => Row(children: [
              Radio(value: i, groupValue: _correctAnswerIndex, onChanged: (v) => setState(() => _correctAnswerIndex = v as int)),
              Expanded(child: TextField(controller: _optionControllers[i], decoration: InputDecoration(labelText: "Option ${i+1}"))),
            ])),
            ElevatedButton(onPressed: _addQuestion, child: const Text("Add Question")),
          ],
        ),
      ),
    );
  }
}