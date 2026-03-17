// lib/screens/admin_dashboard_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminDashboardTab extends StatefulWidget {
  const AdminDashboardTab({super.key});

  @override
  State<AdminDashboardTab> createState() => _AdminDashboardTabState();
}

class _AdminDashboardTabState extends State<AdminDashboardTab> {
  String _memberFilter = 'Today';
  bool _isCleaning = false;

  // 🚀 Chat Cleanup Logic (Inside Dashboard)
  Future<void> _clearOldChats() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Clear Old Chats", style: TextStyle(color: Colors.white)),
        content: const Text("පැය 24කට වඩා පරණ සියලුම මැසේජ් මැකීමට ඔබට සහතිකද?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Yes, Clear", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    ) ?? false;

    if (!confirm) return;

    setState(() => _isCleaning = true);

    try {
      DateTime limit = DateTime.now().subtract(const Duration(hours: 24));
      var snapshot = await FirebaseFirestore.instance
          .collection('global_chat')
          .where('createdAt', isLessThan: Timestamp.fromDate(limit))
          .get();

      if (snapshot.docs.isEmpty) {
        _showSnackBar("පැය 24කට වඩා පරණ මැසේජ් කිසිවක් හමු නොවීය.");
      } else {
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        _showSnackBar("පරණ මැසේජ් ${snapshot.docs.length}ක් සාර්ථකව මකා දමන ලදී!");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    } finally {
      setState(() => _isCleaning = false);
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'App Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        
        // --- MAIN STATS ---
        _buildStatRow('Total Users', 'users', Icons.people, Colors.blue),
        const SizedBox(height: 12),
        _buildStatRow('Total Categories', 'categories', Icons.category, Colors.teal),
        const SizedBox(height: 12),
        _buildStatRow('Total Papers', 'papers', Icons.description, Colors.indigo, isGroup: true),
        const SizedBox(height: 12),
        _buildStatRow('Total Questions', 'questions', Icons.quiz, Colors.orange, isGroup: true),
        const SizedBox(height: 12),

        // --- MAINTENANCE CARD (CLEAR CHAT BUTTON HERE) ---
        _buildMaintenanceCard(),

        const SizedBox(height: 12),
        _buildRealUsageSection(),
        
        const SizedBox(height: 25),

        const Text(
          'Papers per Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        _buildCategoryBreakdown(),

        const SizedBox(height: 25),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'New Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            _buildFilterDropdown(),
          ],
        ),
        const SizedBox(height: 12),
        _buildNewMembersList(),
      ],
    );
  }

  // New Maintenance Card for the Dashboard
  Widget _buildMaintenanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cleaning_services, color: Colors.redAccent, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Chat Cleanup", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text("Clear messages older than 24h", style: TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isCleaning ? null : _clearOldChats,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isCleaning 
              ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text("Clear Now", style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String collection, IconData icon, Color color, {bool isGroup = false}) {
    Stream<AggregateQuerySnapshot> stream = isGroup 
        ? FirebaseFirestore.instance.collectionGroup(collection).count().get().asStream()
        : FirebaseFirestore.instance.collection(collection).count().get().asStream();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          StreamBuilder<AggregateQuerySnapshot>(
            stream: stream,
            builder: (context, snap) {
              return Text('${snap.data?.count ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold));
            },
          )
        ],
      ),
    );
  }

  Widget _buildRealUsageSection() {
    return StreamBuilder<List<int>>(
      stream: _getAllCounts(),
      builder: (context, snap) {
        int totalDocs = snap.hasData ? snap.data!.reduce((a, b) => a + b) : 0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text('Firestore Active Load', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 15),
              _buildUsageRow('Reads (Potential)', '$totalDocs Docs', totalDocs / 50000), 
              const SizedBox(height: 10),
              _buildUsageRow('Writes (Potential)', '$totalDocs Entries', totalDocs / 20000),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryBreakdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('categories').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return Column(
          children: snap.data!.docs.map((doc) {
            return FutureBuilder<AggregateQuerySnapshot>(
              future: FirebaseFirestore.instance.collection('categories').doc(doc.id).collection('papers').count().get(),
              builder: (context, paperSnap) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(doc['name'] ?? 'Unknown', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                      Text('${paperSnap.data?.count ?? 0} Papers', style: const TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Stream<List<int>> _getAllCounts() async* {
    while (true) {
      final users = await FirebaseFirestore.instance.collection('users').count().get();
      final cats = await FirebaseFirestore.instance.collection('categories').count().get();
      final papers = await FirebaseFirestore.instance.collectionGroup('papers').count().get();
      final quests = await FirebaseFirestore.instance.collectionGroup('questions').count().get();
      yield [users.count ?? 0, cats.count ?? 0, papers.count ?? 0, quests.count ?? 0];
      await Future.delayed(const Duration(minutes: 5)); 
    }
  }

  Widget _buildUsageRow(String label, String value, double progress) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)), Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: Colors.white10, color: Colors.cyanAccent, minHeight: 4),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12), height: 35, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _memberFilter, dropdownColor: const Color(0xFF1E293B), style: const TextStyle(color: Colors.cyanAccent, fontSize: 13),
          items: ['Today', 'Week', 'Month'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => _memberFilter = v!),
        ),
      ),
    );
  }

  Widget _buildNewMembersList() {
    DateTime startTime = _memberFilter == 'Today' ? DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day) : _memberFilter == 'Week' ? DateTime.now().subtract(const Duration(days: 7)) : DateTime(DateTime.now().year, DateTime.now().month, 1);
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').where('createdAt', isGreaterThanOrEqualTo: startTime).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox();
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var user = snap.data!.docs[i].data() as Map<String, dynamic>;
            DateTime joinDate = (user['createdAt'] as Timestamp).toDate();
            return Container(
              margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [CircleAvatar(radius: 18, backgroundColor: (user['isPremium'] ?? false) ? Colors.amber.withOpacity(0.2) : Colors.blue.withOpacity(0.2), child: Text(user['name']?[0].toUpperCase() ?? 'U', style: TextStyle(color: (user['isPremium'] ?? false) ? Colors.amber : Colors.blue, fontSize: 14))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user['name'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text(DateFormat('MMM dd, hh:mm a').format(joinDate), style: const TextStyle(color: Colors.white38, fontSize: 10))])), if (user['isPremium'] ?? false) const Icon(Icons.star, color: Colors.amber, size: 16)]),
            );
          },
        );
      },
    );
  }
}