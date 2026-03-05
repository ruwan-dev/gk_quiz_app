import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();

  // 🚀 නම Update කරන ෆන්ක්ෂන් එක
  void _updateName() async {
    if (_nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'name': _nameController.text,
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
        
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String name = userData?['name'] ?? user?.email?.split('@')[0] ?? 'User';
        int score = userData?['totalScore'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              
              // 🖼️ Profile Picture Header
              Center(
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF38BDF8), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        child: const Icon(Icons.person, size: 65, color: Color(0xFF38BDF8)),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text(user?.email ?? '', style: const TextStyle(color: Colors.white38, fontSize: 14)),
              
              const SizedBox(height: 35),
              
              // 📊 Stats Grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard("Total XP", "$score", Icons.auto_awesome, Colors.amber),
                  _buildStatCard("Global Rank", "#1", Icons.emoji_events, Colors.cyanAccent), // Rank එක පසුව dynamic කරමු
                ],
              ),
              
              const SizedBox(height: 35),
              
              // 📝 Edit Section Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.manage_accounts, color: Color(0xFF38BDF8), size: 20),
                        SizedBox(width: 10),
                        Text("Profile Settings", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController..text = name,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Display Name",
                        labelStyle: const TextStyle(color: Colors.white38),
                        floatingLabelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.white38),
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
                          elevation: 0,
                        ),
                        onPressed: _updateName,
                        child: const Text("Save Changes", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}