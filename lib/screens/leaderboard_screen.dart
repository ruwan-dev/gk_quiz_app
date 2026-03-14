import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_constants.dart';

class LeaderboardScreen extends StatelessWidget {
  final Function(String) onNavigate; // 🚀 Tab මාරු කරන්න function එක

  const LeaderboardScreen({super.key, required this.onNavigate});

  void _showRankingInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, 
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.95), 
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
                onPressed: () => _showRankingInfo(context),
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

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['isDeactivated'] != true;
              }).toList();

              if (docs.isEmpty) {
                return const Center(child: Text("No rankings yet!", style: TextStyle(color: Colors.white70)));
              }

              bool isCurrentUserPremium = false;
              Map<String, dynamic>? myData;
              int myRank = 0;

              for (int i = 0; i < docs.length; i++) {
                if (docs[i].id == currentUserId) {
                  myData = docs[i].data() as Map<String, dynamic>;
                  isCurrentUserPremium = myData['isPremium'] ?? false;
                  myRank = i + 1; 
                  break;
                }
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final int rank = index + 1;
                        
                        final String email = data['email'] ?? 'Anonymous';
                        final String name = data['name'] ?? email.split('@')[0];
                        final int score = data['totalScore'] ?? 0;
                        final bool isMe = docs[index].id == currentUserId;
                        final bool isPremium = data['isPremium'] ?? false;
                        final String? avatarUrl = data['avatarUrl'];

                        if (isMe && !isCurrentUserPremium) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF38BDF8).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isMe ? const Color(0xFF38BDF8) : Colors.white10),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    "#$rank", 
                                    style: TextStyle(color: isPremium ? Colors.amber : Colors.white54, fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                ),
                                const SizedBox(width: 10),
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isPremium ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                                  child: (avatarUrl == null || avatarUrl.isEmpty)
                                      ? Icon(isPremium ? Icons.workspace_premium : Icons.person, size: 20, color: isPremium ? Colors.amber : const Color(0xFF38BDF8))
                                      : null,
                                ),
                              ],
                            ),
                            
                            title: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    isMe ? "You ($name)" : name,
                                    style: TextStyle(
                                      color: isMe ? const Color(0xFF38BDF8) : Colors.white, 
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPremium) ...[
                                  const SizedBox(width: 5),
                                  const Icon(Icons.verified, color: Color(0xFF10B981), size: 16),
                                ],
                              ],
                            ),
                            
                            trailing: Text(
                              "$score XP",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (myData != null && !isCurrentUserPremium)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        border: const Border(top: BorderSide(color: Colors.white12, width: 1.5)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                              child: Text(
                                "#$myRank",
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text("Your Global Rank", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                const SizedBox(height: 4),
                                ImageFiltered(
                                  imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                                  child: Text("${myData['totalScore'] ?? 0} XP", style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                          
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => onNavigate("Premium"), // 🚀 කෙලින්ම Premium Tab එකට යනවා
                            child: const Text("View Rank", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}