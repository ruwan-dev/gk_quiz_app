import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'help_screen.dart';
import '../utils/app_constants.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _nameController = TextEditingController();
  
  late AnimationController _brandingController;

  final List<String> _avatarList = [
    "https://api.dicebear.com/7.x/avataaars/png?seed=Felix",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Aneka",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Mimi",
    "https://api.dicebear.com/7.x/avataaars/png?seed=Leo",
    "https://api.dicebear.com/7.x/adventurer/png?seed=Abby",
    "https://api.dicebear.com/7.x/adventurer/png?seed=Jack",
    "https://api.dicebear.com/7.x/bottts/png?seed=Robot1",
    "https://api.dicebear.com/7.x/bottts/png?seed=Robot2",
    "https://api.dicebear.com/7.x/bottts/png?seed=Robot3",
  ];

  @override
  void initState() {
    super.initState();
    _brandingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
  }

  @override
  void dispose() {
    _brandingController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateName() async {
    if (_nameController.text.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
        'name': _nameController.text,
      });
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
        );
        FocusScope.of(context).unfocus(); 
      }
    }
  }

  void _showAvatarSelectionDialog(String? currentAvatar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Choose Your Avatar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            itemCount: _avatarList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, 
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemBuilder: (context, index) {
              final url = _avatarList[index];
              final isSelected = url == currentAvatar; 

              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context); 
                  
                  await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({
                    'avatarUrl': url,
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Avatar Updated! ✨"), backgroundColor: Color(0xFF10B981)),
                    );
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF38BDF8) : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: const Color(0xFF38BDF8).withOpacity(0.5), blurRadius: 10)
                    ] : [],
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    backgroundImage: NetworkImage(url),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel", style: TextStyle(color: Colors.white60))
          ),
        ],
      ),
    );
  }

  void _showAboutUsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
                border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(
                  'assets/logo.png', 
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.rocket_launch_rounded, color: Color(0xFF38BDF8), size: 40),
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text("AstroQuiz", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: 1.5)),
            const SizedBox(height: 5),
            
            const Text(AppConstants.appVersion, style: TextStyle(color: Colors.white24, fontSize: 10)),
            
            const SizedBox(height: 20),
            
            const Text(
              "මෙම යෙදුම සුදුසුකම්ලත් දේශක මණ්ඩලයක් විසින් AI තාක්ෂණය භාවිතා කරමින්, ඔබට කරුණු පහසුවෙන් මතක තබා ගත හැකි වන අයුරින් නිර්මාණය කර ඇත.\n\n"
              "නවතම විෂය නිර්දේශයන්ට අනුකූලව දිනපතා යාවත්කාලීන වන ප්‍රශ්න පත්‍ර මෙහි අඩංගු වන අතර, දිවයිනේම සිසුන් අතරින් ඔබේ දක්ෂතාවය පරීක්ෂා කර ගැනීමට Ranking පහසුකමද සලසා ඇත.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70, 
                fontSize: 13, 
                height: 1.6,
                fontFamily: 'SinhalaFont',
              ),
            ),
            
            const SizedBox(height: 25),
            const Divider(color: Colors.white10, thickness: 1),
            const SizedBox(height: 15),
            
            const Text("CONTACT US", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 15),
            
            _buildContactItem(
              icon: Icons.chat_bubble_outline,
              label: AppConstants.phoneNumber, 
              color: const Color(0xFF25D366),
            ),
            
            const SizedBox(height: 20),
            
            Text(
              "POWERED BY",
              style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 8, letterSpacing: 2),
            ),
            const SizedBox(height: 4),

            AnimatedBuilder(
              animation: _brandingController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF9C27B0).withOpacity(0.6), 
                        const Color(0xFF00ACC1).withOpacity(0.8), 
                        const Color(0xFF38BDF8),                  
                        const Color(0xFFE040FB).withOpacity(0.8), 
                        const Color(0xFF9C27B0).withOpacity(0.6), 
                      ],
                      stops: [
                        0.0,
                        (_brandingController.value - 0.4).clamp(0.0, 1.0),
                        _brandingController.value,
                        (_brandingController.value + 0.4).clamp(0.0, 1.0),
                        1.0,
                      ],
                    ).createShader(bounds);
                  },
                  child: const Text(
                    AppConstants.companyName,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Got it!", style: TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold))
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required String label, required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)));
        
        var userData = snapshot.data!.data() as Map<String, dynamic>?;
        String name = userData?['name'] ?? user?.email?.split('@')[0] ?? 'User';
        bool isPremium = userData?['isPremium'] ?? false;
        String? avatarUrl = userData?['avatarUrl']; 

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: MediaQuery.of(context).viewInsets.bottom != 0 
                  ? const BouncingScrollPhysics() 
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                      children: [
                        const SizedBox(height: 10),
                        
                        Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (isPremium) {
                                  _showAvatarSelectionDialog(avatarUrl); 
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Avatar customization is a Premium feature!"), 
                                      backgroundColor: Colors.orangeAccent,
                                      behavior: SnackBarBehavior.floating,
                                    )
                                  );
                                }
                              },
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isPremium ? const Color(0xFF10B981) : const Color(0xFF38BDF8), 
                                        width: 2.0
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      radius: 40,
                                      backgroundColor: isPremium ? const Color(0xFF10B981).withOpacity(0.15) : Colors.white.withOpacity(0.05),
                                      backgroundImage: (isPremium && avatarUrl != null && avatarUrl.isNotEmpty) 
                                          ? NetworkImage(avatarUrl) 
                                          : null,
                                      child: (!isPremium || avatarUrl == null || avatarUrl.isEmpty)
                                          ? Icon(
                                              isPremium ? Icons.workspace_premium : Icons.person, 
                                              size: 40, 
                                              color: isPremium ? Colors.amber : const Color(0xFF38BDF8)
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (isPremium)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                                      child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                                if (isPremium) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Color(0xFF10B981), size: 20),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(user?.email ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatCard("Total XP", "${userData?['totalScore'] ?? 0}", Icons.auto_awesome, Colors.amber, isPremium: isPremium),
                            const SizedBox(width: 15),
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('users')
                                  .orderBy('totalScore', descending: true)
                                  .snapshots(),
                              builder: (context, rankSnapshot) {
                                String rankText = "#-";
                                if (rankSnapshot.hasData) {
                                  final docs = rankSnapshot.data!.docs.where((doc) {
                                    final data = doc.data() as Map<String, dynamic>? ?? {};
                                    return data['isDeactivated'] != true;
                                  }).toList();
                                  
                                  int myRank = 0;
                                  for (int i = 0; i < docs.length; i++) {
                                    if (docs[i].id == user?.uid) {
                                      myRank = i + 1;
                                      break;
                                    }
                                  }
                                  if (myRank > 0) {
                                    rankText = "#$myRank";
                                  }
                                }
                                return _buildStatCard("Global Rank", rankText, Icons.emoji_events, Colors.cyanAccent, isPremium: isPremium);
                              },
                            ),
                          ],
                        ),
                        
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _nameController..text = name,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: "Display Name",
                                  labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF38BDF8))),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white38, size: 18),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.check_circle, color: Color(0xFF38BDF8), size: 20),
                                    onPressed: _updateName,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildSmallMenuTile(
                                icon: Icons.help_outline,
                                title: "Help & Support",
                                color: const Color(0xFF10B981),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                              ),
                              const SizedBox(height: 8),
                              _buildSmallMenuTile(
                                icon: Icons.info_outline,
                                title: "About Us",
                                color: const Color(0xFF38BDF8),
                                onTap: _showAboutUsDialog,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  Widget _buildSmallMenuTile({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {required bool isPremium}) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          isPremium 
              ? Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
              : ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Text(value, style: const TextStyle(color: Colors.white54, fontSize: 15, fontWeight: FontWeight.bold)),
                ),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }
}