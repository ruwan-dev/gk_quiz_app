import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../utils/app_constants.dart'; 

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  void _sendMessage(String name, int currentCount, String todayDate) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (currentCount >= AppConstants.maxDailyMessages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("You have reached the daily limit of ${AppConstants.maxDailyMessages} messages."),
          backgroundColor: Colors.orangeAccent,
        )
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _messageController.clear(); 
      
      bool isSupport = text.toLowerCase().startsWith('@support');

      bool success = await _dbService.sendChatMessage(
        userId: user.uid,
        userName: name,
        text: text,
        isSupport: isSupport, 
      );
      
      if (success) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'lastChatDate': todayDate,
          'chatCount': currentCount + 1,
        }, SetOptions(merge: true));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send message.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, userSnap) {
        bool isPremium = false;
        String userName = 'User';
        int todayChatCount = 0;
        
        String todayDate = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
        
        if (userSnap.hasData && userSnap.data!.exists) {
          final data = userSnap.data!.data() as Map<String, dynamic>?;
          isPremium = data?['isPremium'] ?? false;
          userName = data?['name'] ?? 'User';
          
          if (data?['lastChatDate'] == todayDate) {
            todayChatCount = data?['chatCount'] ?? 0;
          }
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Community Chat", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false, 
          ),
          body: Column(
            children: [
              // 🚀 Chat Messages Area
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _dbService.getChatMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("No messages yet. Be the first to say hi!", style: TextStyle(color: Colors.white54)));
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      reverse: true, 
                      padding: const EdgeInsets.all(15),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isMe = data['userId'] == currentUser?.uid;
                        final isSupportMsg = data['isSupport'] ?? false; 

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                            decoration: BoxDecoration(
                              color: isSupportMsg ? Colors.amber.withOpacity(0.15) : (isMe ? const Color(0xFF38BDF8) : Colors.white.withOpacity(0.1)),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(15),
                                topRight: const Radius.circular(15),
                                bottomLeft: isMe ? const Radius.circular(15) : const Radius.circular(0),
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(15),
                              ),
                              border: isSupportMsg ? Border.all(color: Colors.amber.withOpacity(0.5)) : null,
                            ),
                            child: Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (isSupportMsg) ...[
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.support_agent, color: Colors.amber, size: 14),
                                      const SizedBox(width: 5),
                                      Text("SUPPORT REQUEST", style: TextStyle(color: Colors.amber.shade300, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                ],

                                if (!isMe) ...[
                                  Text(data['userName'] ?? 'User', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                ],
                                
                                Text(
                                  data['text'] ?? '', 
                                  style: TextStyle(
                                    color: (isMe && !isSupportMsg) ? Colors.black87 : Colors.white, 
                                    fontSize: 15
                                  )
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 🚀 Chat එකට යටින් සහ Input Box එකට උඩින් තියෙන Watermark එක
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Colors.white24, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      "POWERED BY ${AppConstants.companyName}",
                      style: const TextStyle(
                        color: Colors.white24, 
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.5
                      ),
                    ),
                  ],
                ),
              ),

              // 🚀 Type කරන Input Area එක
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.9),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: isPremium
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0, left: 5.0),
                            child: Row(
                              children: [
                                Text(
                                  "Messages sent today: $todayChatCount / ${AppConstants.maxDailyMessages}", 
                                  style: TextStyle(
                                    color: todayChatCount >= AppConstants.maxDailyMessages ? Colors.redAccent : Colors.white54, 
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold
                                  )
                                ),
                                const Spacer(),
                                const Text(
                                  "Type @support for help",
                                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _messageController,
                                  style: const TextStyle(color: Colors.white),
                                  enabled: todayChatCount < AppConstants.maxDailyMessages, 
                                  decoration: InputDecoration(
                                    hintText: todayChatCount >= AppConstants.maxDailyMessages ? "Daily limit reached..." : "Type a message...",
                                    hintStyle: const TextStyle(color: Colors.white38),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {
                                  if (todayChatCount < AppConstants.maxDailyMessages) {
                                    _sendMessage(userName, todayChatCount, todayDate);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: todayChatCount >= AppConstants.maxDailyMessages ? Colors.grey.withOpacity(0.5) : const Color(0xFF38BDF8), 
                                    shape: BoxShape.circle
                                  ),
                                  child: const Icon(Icons.send, color: Colors.black87, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(15), 
                          border: Border.all(color: Colors.amber.withOpacity(0.3))
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.workspace_premium, color: Colors.amber, size: 20),
                            SizedBox(width: 10),
                            Text("Upgrade to Premium to send messages", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}