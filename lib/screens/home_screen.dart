import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/icon_helper.dart';
import 'papers_screen.dart';
import 'admin_panel.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart'; 
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Widget> _getScreens(bool isAdmin) {
    return [
      const HomeTab(),
      const LeaderboardScreen(),
      const ProfileScreen(), 
      if (isAdmin) const AdminPanel(),
    ];
  }

  // 🚀 යාවත්කාලීන කළ Navigation Logic එක
  void _onItemTapped(int index, bool isAdmin, bool isDeactivated) {
    int logoutIndex = isAdmin ? 4 : 3;

    // 1. මුලින්ම බලනවා එබුවේ Logout බටන් එකද කියලා
    if (index == logoutIndex) {
      _showLogoutDialog();
      return; // Logout dialog එක පෙන්නලා මෙතනින් නවතිනවා
    }

    // 2. Logout නෙවෙයි නම් සහ යූසර් Deactivate වෙලා නම් අනිත් Tabs වලට යන්න දෙන්නේ නැහැ
    if (isDeactivated) {
      _showDeactivatedSnackBar();
      return;
    }

    // 3. සාමාන්‍ය යූසර් කෙනෙක් නම් Tab එක මාරු කරනවා
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showDeactivatedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Access Denied: Your account is deactivated."),
        backgroundColor: Colors.redAccent,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainBackgroundWrapper(child: LoginScreen())));
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final bool isAdmin = currentUser?.email == "admin@gmail.com";

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
      builder: (context, snapshot) {
        bool isDeactivated = false;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isDeactivated = data?['isDeactivated'] ?? false;
        }

        final List<Widget> screens = _getScreens(isAdmin);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text(""),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Column(
            children: [
              if (isDeactivated)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.report_problem, color: Colors.white),
                      SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          "Your account is deactivated. Please contact admin.",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: AbsorbPointer(
                  absorbing: isDeactivated,
                  child: Opacity(
                    opacity: isDeactivated ? 0.4 : 1.0,
                    child: screens[_selectedIndex],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12, width: 1))),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: isDeactivated ? Colors.white24 : const Color(0xFF38BDF8),
              unselectedItemColor: Colors.white24,
              currentIndex: _selectedIndex,
              onTap: (index) => _onItemTapped(index, isAdmin, isDeactivated),
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                const BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Rank"),
                const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
                if (isAdmin) const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"),
                const BottomNavigationBarItem(icon: Icon(Icons.logout, color: Colors.redAccent), label: "Logout"),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 🏠 HomeTab (මෙහි වෙනසක් අවශ්‍ය නැත)
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 80);
              var userData = snapshot.data!.data() as Map<String, dynamic>?;
              String name = userData?['name'] ?? currentUser?.email?.split('@')[0] ?? 'User';
              int score = userData?['totalScore'] ?? 0;

              return Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                    child: const Icon(Icons.person, color: Color(0xFF38BDF8), size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_getGreeting(), style: const TextStyle(color: Colors.white38, fontSize: 13)),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                        const SizedBox(width: 5),
                        Text("$score XP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          const Text("Select Category", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('categories').orderBy('createdAt', descending: false).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No categories found", style: TextStyle(color: Colors.white70)));

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.1,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    IconData categoryIcon = IconHelper.getIcon(data['iconKey']);
                    return _buildCategoryCard(context, data['name'], categoryIcon, const Color(0xFF38BDF8), data['id']);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, IconData icon, Color iconColor, String catId) {
    return Material(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => MainBackgroundWrapper(child: PapersScreen(categoryId: catId, categoryName: title))));
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 35, color: iconColor)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}