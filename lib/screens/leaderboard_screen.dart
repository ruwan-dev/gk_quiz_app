import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          "🏆 Global Ranking 🏆",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // වැඩිම ලකුණු ගත්ත අය පිළිවෙළට ගන්නවා
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('totalScore', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No rankings available yet!", 
                  style: TextStyle(color: Colors.white70))
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final int rank = index + 1;
                  final String email = data['email'] ?? 'Anonymous';
                  final int score = data['totalScore'] ?? 0;
                  final bool isMe = docs[index].id == currentUserId;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isMe ? Colors.blueAccent : Colors.white10,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : Colors.blueGrey)),
                        child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        isMe ? "You ($email)" : email.split('@')[0], // Email එකේ මුල් කෑල්ල විතරක් පෙන්වන්න
                        style: TextStyle(
                          color: isMe ? Colors.blueAccent : Colors.white,
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        "$score XP",
                        style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}