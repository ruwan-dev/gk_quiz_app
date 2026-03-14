import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚀 Clipboard පහසුකම සඳහා
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert'; 
import 'dart:math' as math;
import '../utils/icon_helper.dart';
import '../utils/gemini_loader.dart'; 
import '../utils/app_prompts.dart'; // 🚀 Prompts ගබඩා කර ඇති ෆයිල් එක
import 'admin_issues_screen.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  // --- CONTROLLERS ---
  final TextEditingController _catNameController = TextEditingController();
  final TextEditingController _catIdController = TextEditingController();
  final TextEditingController _paperIdController = TextEditingController();
  final TextEditingController _paperTitleController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController _explanationController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  // --- SELECTION STATE ---
  String _selectedIconKey = 'star';
  int _correctAnswerIndex = 0;
  String? _selectedCatForPaper, _selectedCatForQuest, _selectedPaperForQuest;
  String? _selectedCatForManage, _selectedCatForQManage, _selectedPaperForQManage;

  // --- HELPER FUNCTIONS ---
  void _showSnackBar(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirm(String title, String desc) async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(desc, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes", style: TextStyle(color: Colors.redAccent))),
        ],
      )
    ) ?? false;
  }

  // --- LOGIC FUNCTIONS ---
  void _addCategory() async {
    if (_catNameController.text.isNotEmpty && _catIdController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('categories').doc(_catIdController.text).set({
        'name': _catNameController.text, 'id': _catIdController.text, 'iconKey': _selectedIconKey, 'createdAt': Timestamp.now(), 'isVisible': true, 'isNew': false, 'isDisabled': false,
      });
      _catNameController.clear(); _catIdController.clear(); _showSnackBar("Category Added!");
    }
  }

  void _deleteCategory(String catId) async {
    if (await _confirm("Delete Category", "Delete this category?")) {
      await FirebaseFirestore.instance.collection('categories').doc(catId).delete();
      _showSnackBar("Category Deleted!");
    }
  }

  void _addPaper() async {
    if (_selectedCatForPaper != null && _paperIdController.text.isNotEmpty) {
      String title = _paperTitleController.text.isNotEmpty ? _paperTitleController.text : _paperIdController.text.toUpperCase();
      await FirebaseFirestore.instance.collection('categories').doc(_selectedCatForPaper).collection('papers').doc(_paperIdController.text).set({
        'title': title, 'createdAt': Timestamp.now(), 'isVisible': true, 'isPremium': false,
      });
      _paperIdController.clear(); _paperTitleController.clear(); _showSnackBar("Paper Added!");
    }
  }

  void _deletePaper(String catId, String paperId) async {
    if (await _confirm("Delete Paper", "Delete this paper?")) {
      await FirebaseFirestore.instance.collection('categories').doc(catId).collection('papers').doc(paperId).delete();
      _showSnackBar("Paper Deleted!");
    }
  }

  void _addQuestion() async {
    if (_selectedPaperForQuest != null && _questionController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('categories').doc(_selectedCatForQuest).collection('papers').doc(_selectedPaperForQuest).collection('questions').add({
        'questionText': _questionController.text, 'options': _optionControllers.map((c) => c.text).toList(), 'correctAnswerIndex': _correctAnswerIndex, 'explanation': _explanationController.text, 'imageUrl': _imageUrlController.text, 'createdAt': Timestamp.now(),
      });
      _questionController.clear(); _imageUrlController.clear(); _explanationController.clear();
      for (var c in _optionControllers) { c.clear(); }
      setState(() => _correctAnswerIndex = 0); _showSnackBar("Question Added!");
    }
  }

  void _deleteQuestion(String c, String p, String q) async {
    if (await _confirm("Delete Question", "Are you sure?")) {
      await FirebaseFirestore.instance.collection('categories').doc(c).collection('papers').doc(p).collection('questions').doc(q).delete();
      _showSnackBar("Question Deleted!");
    }
  }

  void _updateUserStatus(String userId, bool shouldDeactivate) async {
    String action = shouldDeactivate ? "Deactivate" : "Activate";
    if (await _confirm("$action User", "Do you want to $action this user?")) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isDeactivated': shouldDeactivate});
      _showSnackBar("User updated successfully!");
    }
  }

  void _updateUserPremiumStatus(String userId, bool isPremium) async {
    String action = isPremium ? "Upgrade to Premium" : "Remove Premium";
    if (await _confirm(action, "Do you want to $action for this user?")) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({'isPremium': isPremium});
      _showSnackBar("User premium status updated!");
    }
  }

  void _updatePaperPremiumStatus(String catId, String paperId, bool isPremium) async {
    String action = isPremium ? "Make Premium" : "Remove Premium";
    if (await _confirm(action, "Do you want to $action for this paper?")) {
      await FirebaseFirestore.instance.collection('categories').doc(catId).collection('papers').doc(paperId).update({'isPremium': isPremium});
      _showSnackBar("Paper premium status updated!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 8, 
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          title: const Text("Admin Management", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Color(0xFF38BDF8),
            labelColor: Color(0xFF38BDF8),
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: "Category", icon: Icon(Icons.category)),
              Tab(text: "Paper", icon: Icon(Icons.note_add)),
              Tab(text: "Manage Papers", icon: Icon(Icons.edit_note)),
              Tab(text: "Question", icon: Icon(Icons.add_task)),
              Tab(text: "Bulk Upload", icon: Icon(Icons.cloud_upload)), 
              Tab(text: "Manage Quests", icon: Icon(Icons.settings_suggest)),
              Tab(text: "Users", icon: Icon(Icons.people_alt_rounded)),
              Tab(text: "Issues", icon: Icon(Icons.bug_report)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabWrapper(_buildAddCategoryTab()),
            _buildTabWrapper(_buildAddPaperTab()),
            _buildTabWrapper(_buildManagePapersTab()),
            _buildTabWrapper(_buildAddQuestionTab()),
            _buildTabWrapper(const BulkUploadTab()), 
            _buildTabWrapper(_buildManageQuestionsTab()),
            _buildTabWrapper(_buildManageUsersTab()),
            const AdminIssuesScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabWrapper(Widget child) => SingleChildScrollView(padding: const EdgeInsets.all(20), child: child);

  // --- TAB CONTENTS ---
  Widget _buildAddCategoryTab() => Column(children: [_buildGlassCard("Add New Category", Colors.cyanAccent, [_buildTextField(_catNameController, "Name"), _buildTextField(_catIdController, "ID"), _buildIconPicker(), _buildButton(_addCategory, "Save Category", Colors.cyan.shade700)]), const SizedBox(height: 20), _buildGlassCard("Manage Existing Categories", Colors.cyan, [_buildCategoryList()])]);
  Widget _buildAddPaperTab() => _buildGlassCard("Add New Paper", Colors.orangeAccent, [_buildCatDrop((v) => setState(() => _selectedCatForPaper = v), _selectedCatForPaper), _buildTextField(_paperIdController, "Paper ID (Ex: paper_1)"), _buildTextField(_paperTitleController, "Paper Name (Sinhala/English)"), _buildButton(_addPaper, "Save Paper", Colors.orange.shade700)]);
  Widget _buildManagePapersTab() => _buildGlassCard("Manage Existing Papers", Colors.redAccent, [_buildCatDrop((v) => setState(() => _selectedCatForManage = v), _selectedCatForManage), if (_selectedCatForManage != null) _buildPapersList(_selectedCatForManage!)]);
  Widget _buildAddQuestionTab() => _buildGlassCard("Add New Questions", Colors.greenAccent, [_buildCatDrop((v) => setState(() { _selectedCatForQuest = v; _selectedPaperForQuest = null; }), _selectedCatForQuest), _buildPaperDrop(_selectedCatForQuest, _selectedPaperForQuest, (v) => setState(() => _selectedPaperForQuest = v)), _buildTextField(_questionController, "Question Text", maxLines: 2), _buildTextField(_imageUrlController, "Image URL"), ...List.generate(4, (i) => Row(children: [Radio(value: i, groupValue: _correctAnswerIndex, activeColor: Colors.greenAccent, onChanged: (v) => setState(() => _correctAnswerIndex = v as int)), Expanded(child: _buildTextField(_optionControllers[i], "Option ${i+1}"))])), _buildTextField(_explanationController, "Explanation"), _buildButton(_addQuestion, "Save Question", Colors.green.shade700)]);
  Widget _buildManageQuestionsTab() => _buildGlassCard("Manage Questions", Colors.purpleAccent, [_buildCatDrop((v) => setState(() { _selectedCatForQManage = v; _selectedPaperForQManage = null; }), _selectedCatForQManage), _buildPaperDrop(_selectedCatForQManage, _selectedPaperForQManage, (v) => setState(() => _selectedPaperForQManage = v)), if (_selectedPaperForQManage != null) _buildQuestList(_selectedCatForQManage!, _selectedPaperForQManage!)]);

  // 🚀 Fixed _buildManageUsersTab with correct syntax
  Widget _buildManageUsersTab() {
    return _buildGlassCard("App Users Access", Colors.yellowAccent, [
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('totalScore', descending: true).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const LinearProgressIndicator();
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              var data = snap.data!.docs[i].data() as Map<String, dynamic>;
              bool deact = data['isDeactivated'] ?? false;
              bool isPremium = data['isPremium'] ?? false;
              String email = data['email'] ?? 'No Email';
              String name = data['name'] ?? email.split('@')[0];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: deact ? Colors.redAccent.withOpacity(0.05) : Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(15),
                  border: isPremium ? Border.all(color: Colors.amber.withOpacity(0.5), width: 1) : null,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: deact 
                        ? Colors.redAccent.withOpacity(0.2) 
                        : (isPremium ? Colors.amber.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2)),
                    child: isPremium && !deact
                        ? const Icon(Icons.star, color: Colors.amber, size: 20)
                        : Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(email, style: TextStyle(color: deact ? Colors.white24 : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text(deact 
                      ? "Blocked • $name" 
                      : "Active${isPremium ? ' • Premium' : ''} • $name • ${data['totalScore'] ?? 0} XP", 
                    style: TextStyle(color: deact ? Colors.redAccent : (isPremium ? Colors.amber : Colors.cyanAccent), fontSize: 11)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isPremium ? Icons.star : Icons.star_border,
                          color: isPremium ? Colors.amber : Colors.white38,
                          size: 26,
                        ),
                        tooltip: isPremium ? "Remove Premium" : "Make Premium",
                        onPressed: () => _updateUserPremiumStatus(snap.data!.docs[i].id, !isPremium),
                      ),
                      IconButton(
                        icon: Icon(
                          deact ? Icons.block : Icons.check_circle,
                          color: deact ? Colors.redAccent : Colors.cyanAccent,
                          size: 24,
                        ),
                        tooltip: deact ? "Unblock User" : "Block User",
                        onPressed: () => _updateUserStatus(snap.data!.docs[i].id, !deact),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    ]);
  }

  // --- UI COMPONENTS ---
  Widget _buildGlassCard(String title, Color accent, List<Widget> children) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 20), ...children]));
  Widget _buildTextField(TextEditingController ctrl, String label, {int maxLines = 1}) => Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(controller: ctrl, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: _inputDeco(label)));
  Widget _buildButton(VoidCallback tap, String label, Color col) => SizedBox(width: double.infinity, height: 48, child: ElevatedButton(onPressed: tap, style: ElevatedButton.styleFrom(backgroundColor: col, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  Widget _buildIconPicker() => Padding(padding: const EdgeInsets.only(bottom: 15), child: SizedBox(height: 45, child: ListView(scrollDirection: Axis.horizontal, children: IconHelper.iconMap.keys.map((k) => GestureDetector(onTap: () => setState(() => _selectedIconKey = k), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: _selectedIconKey == k ? Colors.cyanAccent.withOpacity(0.1) : Colors.white10, shape: BoxShape.circle, border: Border.all(color: _selectedIconKey == k ? Colors.cyanAccent : Colors.transparent)), child: Icon(IconHelper.getIcon(k), color: _selectedIconKey == k ? Colors.cyanAccent : Colors.white38, size: 18)))).toList())));
  Widget _buildCatDrop(Function(String?) fn, String? sel) => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('categories').snapshots(), builder: (context, snap) { if (!snap.hasData) return const SizedBox(); return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: sel, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white), decoration: _inputDeco("Select Category"), items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(), onChanged: fn)); });
  Widget _buildPaperDrop(String? catId, String? sel, Function(String?) fn) => catId == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('categories').doc(catId).collection('papers').snapshots(), builder: (context, snap) { if (!snap.hasData) return const SizedBox(); return Padding(padding: const EdgeInsets.only(bottom: 12), child: DropdownButtonFormField<String>(value: sel, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.white), decoration: _inputDeco("Select Paper"), items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['title']))).toList(), onChanged: fn)); });
  InputDecoration _inputDeco(String l) => InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white38), floatingLabelStyle: const TextStyle(color: Color(0xFF38BDF8)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))));

  Widget _buildCategoryList() => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('categories').snapshots(), builder: (context, snap) { if (!snap.hasData) return const SizedBox(); return Column(children: snap.data!.docs.map((d) { var data = d.data() as Map<String, dynamic>; bool isVisible = data.containsKey('isVisible') ? data['isVisible'] : true; bool isNew = data.containsKey('isNew') ? data['isNew'] : false; bool isDisabled = data.containsKey('isDisabled') ? data['isDisabled'] : false; return ListTile(contentPadding: EdgeInsets.zero, title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(isNew ? Icons.new_releases : Icons.new_releases_outlined, color: isNew ? Colors.redAccent : Colors.white38, size: 22), tooltip: isNew ? "Remove NEW Label" : "Add NEW Label", onPressed: () { FirebaseFirestore.instance.collection('categories').doc(d.id).update({'isNew': !isNew}); }), IconButton(icon: Icon(isDisabled ? Icons.lock : Icons.lock_open, color: isDisabled ? Colors.orangeAccent : Colors.white38, size: 22), tooltip: isDisabled ? "Enable Category" : "Disable Category", onPressed: () { FirebaseFirestore.instance.collection('categories').doc(d.id).update({'isDisabled': !isDisabled}); }), Switch(value: isVisible, activeColor: Colors.cyanAccent, onChanged: (v) { FirebaseFirestore.instance.collection('categories').doc(d.id).update({'isVisible': v}); }), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteCategory(d.id))])); }).toList()); });
  Widget _buildPapersList(String catId) => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('categories').doc(catId).collection('papers').snapshots(), builder: (context, snap) { if (!snap.hasData) return const SizedBox(); return Column(children: snap.data!.docs.map((d) { var data = d.data() as Map<String, dynamic>; bool isVisible = data.containsKey('isVisible') ? data['isVisible'] : true; bool isPremium = data.containsKey('isPremium') ? data['isPremium'] : false; return ListTile(contentPadding: EdgeInsets.zero, title: Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: Icon(isPremium ? Icons.star : Icons.star_border, color: isPremium ? Colors.amber : Colors.white38, size: 24), tooltip: isPremium ? "Remove Premium" : "Make Premium", onPressed: () => _updatePaperPremiumStatus(catId, d.id, !isPremium)), Switch(value: isVisible, activeColor: Colors.orangeAccent, onChanged: (v) { FirebaseFirestore.instance.collection('categories').doc(catId).collection('papers').doc(d.id).update({'isVisible': v}); }), IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deletePaper(catId, d.id))])); }).toList()); });
  Widget _buildQuestList(String c, String p) => StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('categories').doc(c).collection('papers').doc(p).collection('questions').orderBy('createdAt').snapshots(), builder: (context, snap) { if (!snap.hasData) return const SizedBox(); return Column(children: snap.data!.docs.map((d) => ListTile(contentPadding: EdgeInsets.zero, title: Text(d['questionText'], maxLines: 1, style: const TextStyle(color: Colors.white70, fontSize: 13)), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteQuestion(c, p, d.id)))).toList()); });
}

// 🚀 BULK UPLOAD WIDGET 🚀
class BulkUploadTab extends StatefulWidget {
  const BulkUploadTab({super.key});

  @override
  State<BulkUploadTab> createState() => _BulkUploadTabState();
}

class _BulkUploadTabState extends State<BulkUploadTab> {
  final TextEditingController _jsonController = TextEditingController();
  String? _selectedCatId;
  String? _selectedPaperId;
  bool _isLoading = false;

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied!"), backgroundColor: Colors.green),
    );
  }

  Future<void> _processBulkUpload() async {
    if (_jsonController.text.isEmpty || _selectedCatId == null || _selectedPaperId == null) {
      _showSnackBar("Select Cat, Paper and paste JSON!", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<dynamic> questions = jsonDecode(_jsonController.text);
      WriteBatch batch = FirebaseFirestore.instance.batch();
      
      CollectionReference qRef = FirebaseFirestore.instance
          .collection('categories')
          .doc(_selectedCatId)
          .collection('papers')
          .doc(_selectedPaperId)
          .collection('questions');

      for (var q in questions) {
        DocumentReference newDoc = qRef.doc();
        batch.set(newDoc, {
          'questionText': q['question'], 
          'options': q['options'],
          'correctAnswerIndex': q['correctAnswerIndex'] ?? 0, 
          'explanation': q['explanation'] ?? "",
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      _showSnackBar("✅ Uploaded ${questions.length} questions!", Colors.green);
      _jsonController.clear();
      
    } catch (e) {
      _showSnackBar("❌ Error: Invalid JSON or Firestore issue.", Colors.redAccent);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Widget _buildPromptHelper(String title, String prompt, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13))),
          IconButton(icon: const Icon(Icons.copy_all_rounded, color: Color(0xFF38BDF8), size: 20), onPressed: () => _copyToClipboard(prompt, title)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("AI Prompt Helpers", style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildPromptHelper("General Quiz Prompt", AppPrompts.generalQuizPrompt, Icons.psychology),
                  _buildPromptHelper("PDF-based Quiz Prompt", AppPrompts.pdfQuizPrompt, Icons.picture_as_pdf),
                  const Divider(color: Colors.white10, height: 25),
                  const Text("Bulk Upload Data", style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1E293B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDeco("Select Category"),
                        value: _selectedCatId,
                        items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name']))).toList(),
                        onChanged: (v) => setState(() { _selectedCatId = v; _selectedPaperId = null; }),
                      );
                    },
                  ),
                  const SizedBox(height: 15),
                  if (_selectedCatId != null)
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('categories').doc(_selectedCatId).collection('papers').snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return DropdownButtonFormField<String>(
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco("Select Paper"),
                          value: _selectedPaperId,
                          items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['title']))).toList(),
                          onChanged: (v) => setState(() => _selectedPaperId = v),
                        );
                      },
                    ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _jsonController,
                    maxLines: 12,
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(hintText: 'Paste JSON Here...', hintStyle: const TextStyle(color: Colors.white24), fillColor: Colors.black26, filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton.icon(onPressed: _isLoading ? null : _processBulkUpload, icon: const Icon(Icons.bolt_rounded), label: Text(_isLoading ? "Uploading..." : "Start Bulk Upload"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
                ],
              ),
            ),
          ],
        ),
        if (_isLoading) const Center(child: GeminiLoader(size: 80)),
      ],
    );
  }

  InputDecoration _inputDeco(String l) => InputDecoration(labelText: l, labelStyle: const TextStyle(color: Colors.white38), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.greenAccent)));
}