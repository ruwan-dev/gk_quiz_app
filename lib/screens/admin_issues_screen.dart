import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../services/database_service.dart';
import '../utils/gemini_loader.dart';

class AdminIssuesScreen extends StatefulWidget {
  const AdminIssuesScreen({super.key});

  @override
  State<AdminIssuesScreen> createState() => _AdminIssuesScreenState();
}

class _AdminIssuesScreenState extends State<AdminIssuesScreen> {
  final DatabaseService _dbService = DatabaseService();

  void _resolveIssue(String issueId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('issues').doc(issueId).update({
      'isResolved': !currentStatus,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!currentStatus ? "Issue marked as resolved!" : "Issue marked as unresolved!"),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        )
      );
    }
  }

  void _deleteIssue(String issueId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Delete Issue", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to delete this issue?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.redAccent))),
        ],
      )
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('issues').doc(issueId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Issue deleted!"), backgroundColor: Colors.redAccent)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // since it's going to be in a tab view ideally, or standalone
      body: FutureBuilder<List<IssueModel>>(
        future: _dbService.getIssues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: GeminiLoader(size: 60));
          }

          if (snapshot.hasError) {
             return const Center(child: Text("Error fetching issues", style: TextStyle(color: Colors.redAccent)));
          }

          final issues = snapshot.data ?? [];
          
          if (issues.isEmpty) {
            return const Center(child: Text("No issues reported yet.", style: TextStyle(color: Colors.white70)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: issues.length,
            itemBuilder: (context, index) {
              final issue = issues[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: issue.isResolved ? Colors.white.withOpacity(0.02) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: issue.isResolved ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              issue.userEmail, 
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
                            )
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: issue.isResolved ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              issue.isResolved ? "Resolved" : "Pending", 
                              style: TextStyle(
                                color: issue.isResolved ? Colors.greenAccent : Colors.orangeAccent, 
                                fontSize: 12, 
                                fontWeight: FontWeight.bold
                              )
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        issue.description,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            issue.createdAt.toDate().toString().split('.')[0],
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  issue.isResolved ? Icons.undo : Icons.check_circle, 
                                  color: issue.isResolved ? Colors.orangeAccent : Colors.greenAccent
                                ),
                                tooltip: issue.isResolved ? "Mark as Pending" : "Mark as Resolved",
                                onPressed: () {
                                  _resolveIssue(issue.id, issue.isResolved);
                                  setState(() {}); // refresh the future builder locally
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                tooltip: "Delete Issue",
                                onPressed: () {
                                  _deleteIssue(issue.id);
                                  setState(() {}); // refresh the future builder locally
                                },
                              ),
                            ],
                          )
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
