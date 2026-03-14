import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _issueController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  bool _isSubmitting = false;

  void _submitIssue() async {
    if (_issueController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your issue first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool success = await _dbService.reportIssue(
        userId: user.uid,
        userEmail: user.email ?? 'No Email',
        description: _issueController.text.trim(),
      );

      setState(() {
         _isSubmitting = false;
      });

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue reported successfully. Admin will review it.'),
            backgroundColor: Color(0xFF10B981),
          )
        );
        _issueController.clear();
        Navigator.pop(context);
      } else if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to report issue. Try again later.'),
            backgroundColor: Colors.redAccent,
          )
         );
      }
    } else {
      setState(() {
         _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Report an Issue",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // 🚀 මෙන්න මෙතන තමයි භාෂා දෙකෙන්ම උපදෙස් ඇතුළත් කළේ
            const Text(
              "Any Help or Found a bug or have a suggestion? Let us know below. Please include a contact phone number so the admin can reach out to you.\n\nඔබට සහයක් අවශ්‍යද? නැතහොත් යම් දෝෂයක් හමුවුණාද? නැතහොත් යෝජනාවක් තිබෙනවාද? ඒ බව පහතින් අපට දන්වන්න. කරුණාකර ඔබව සම්බන්ධ කරගත හැකි දුරකථන අංකයක්ද ඇතුළත් කරන්න.",
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _issueController,
                    maxLines: 6, // අදහස ලියන්න තව පොඩි ඉඩක් දුන්නා
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Describe your issue and enter your phone number here...\nඔබේ ගැටලුව සහ දුරකථන අංකය මෙහි ඇතුළත් කරන්න...",
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF38BDF8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isSubmitting ? null : _submitIssue,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text("Submit Issue", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}