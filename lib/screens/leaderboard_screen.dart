import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  // 🚀 Ranking හැදෙන විදිය පෙන්වන Banner එක (Modal Bottom Sheet)
  void _showRankingInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Glassy පෙනුම සඳහා
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.95), // තද අළු පැහැති පසුබිම
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 50, height: 5, 
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.stars, color: Colors.amber, size: 28),
                SizedBox(width: 10),
                Text("How Ranking Works", 
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            _buildInfoItem(Icons.check_circle_outline, "Correct Answer", "+10 XP per question"),
            _buildInfoItem(Icons.speed, "Speed Bonus", "Answer faster to get extra points"),
            _buildInfoItem(Icons.emoji_events, "Global Rank", "Your rank is based on total XP earned"),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Got it!", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF38BDF8), size: 24),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: const TextStyle(color: Colors.white60, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        const SizedBox(height: 15),
        // 🏆 Title සහ Info Icon එක සහිත කොටස
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Global Ranking 🏆",
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Color(0xFF38BDF8), size: 26),
                onPressed: () => _showRankingInfo(context), // Info Icon එක ක්ලික් කළ විට
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('totalScore', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No rankings yet!", style: TextStyle(color: Colors.white70)));
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
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF38BDF8).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: isMe ? const Color(0xFF38BDF8) : Colors.white10),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : Colors.white10)),
                        child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        isMe ? "You ($email)" : email.split('@')[0],
                        style: TextStyle(color: isMe ? const Color(0xFF38BDF8) : Colors.white, fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
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