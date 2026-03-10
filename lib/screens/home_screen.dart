import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import '../utils/icon_helper.dart';
import 'papers_screen.dart';
import 'admin_panel.dart';
import 'login_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart'; 
import '../main.dart';
import '../theme/app_theme.dart';

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

  void _onItemTapped(int index, bool isAdmin, bool isDeactivated) {
    int logoutIndex = isAdmin ? 4 : 3;
    if (index == logoutIndex) {
      _showLogoutDialog();
      return;
    }
    if (isDeactivated) {
      _showDeactivatedSnackBar();
      return;
    }
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

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _showPremiumPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const AnimatedPremiumPopup();
      }
    );
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
              bool isPremium = userData?['isPremium'] ?? false;

              return Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: isPremium 
                            ? const Color(0xFF10B981).withOpacity(0.15) 
                            : const Color(0xFF38BDF8).withOpacity(0.2),
                        child: Icon(
                          isPremium ? Icons.workspace_premium : Icons.person, 
                          color: isPremium ? Colors.amber : const Color(0xFF38BDF8), 
                          size: 30
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_getGreeting(), style: const TextStyle(color: Colors.white38, fontSize: 13)),
                            Row(
                              children: [
                                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                if (isPremium) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Color(0xFF10B981), size: 18), 
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPremium ? const Color(0xFF10B981).withOpacity(0.08) : Colors.white.withOpacity(0.05), 
                          borderRadius: BorderRadius.circular(20), 
                          border: Border.all(color: isPremium ? Colors.amber.withOpacity(0.5) : Colors.white10)
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: isPremium ? Colors.amber : Colors.amberAccent, size: 16),
                            const SizedBox(width: 5),
                            Text("$score XP", style: TextStyle(color: isPremium ? const Color(0xFF10B981) : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (!isPremium) ...[
                    const SizedBox(height: 25),
                    GestureDetector(
                      onTap: () => _showPremiumPopup(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFF10B981).withOpacity(0.15), Colors.amber.withOpacity(0.08)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                            ),
                            const SizedBox(width: 15),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Upgrade to Premium", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15)),
                                  SizedBox(height: 6),
                                  Text("Tap here to unlock all features", style: TextStyle(color: Colors.white60, fontSize: 12)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios, color: Color(0xFF10B981), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 35),
          const Text("Select Category", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No categories found", style: TextStyle(color: Colors.white70)));

                final visibleCategories = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data.containsKey('isVisible') && data['isVisible'] == false) {
                    return false;
                  }
                  return true;
                }).toList();

                visibleCategories.sort((a, b) {
                  final dataA = a.data() as Map<String, dynamic>;
                  final dataB = b.data() as Map<String, dynamic>;
                  
                  bool isNewA = dataA.containsKey('isNew') ? dataA['isNew'] : false;
                  bool isNewB = dataB.containsKey('isNew') ? dataB['isNew'] : false;

                  if (isNewA && !isNewB) return -1;
                  if (!isNewA && isNewB) return 1;
                  return 0; 
                });

                if (visibleCategories.isEmpty) {
                  return const Center(child: Text("No categories available", style: TextStyle(color: Colors.white70)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: visibleCategories.length,
                  itemBuilder: (context, index) {
                    final data = visibleCategories[index].data() as Map<String, dynamic>;
                    IconData categoryIcon = IconHelper.getIcon(data['iconKey']);
                    
                    bool isNew = data.containsKey('isNew') ? data['isNew'] : false;
                    bool isDisabled = data.containsKey('isDisabled') ? data['isDisabled'] : false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: AnimatedCategoryCard(
                        title: data['name'],
                        icon: categoryIcon,
                        iconColor: const Color(0xFF38BDF8),
                        catId: data['id'],
                        isNew: isNew,
                        isDisabled: isDisabled,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedPremiumPopup extends StatefulWidget {
  const AnimatedPremiumPopup({super.key});

  @override
  State<AnimatedPremiumPopup> createState() => _AnimatedPremiumPopupState();
}

class _AnimatedPremiumPopupState extends State<AnimatedPremiumPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: GradientBorderPainter(
              angle: _controller.value * 2 * math.pi,
              strokeWidth: 3.0,
              radius: 20,
              gradientColors: const [
                Color(0xFF10B981), // Green
                Colors.amber,      // Gold
                Color(0xFF059669), // Dark Green
                Colors.amber,      // Gold
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), 
            borderRadius: BorderRadius.circular(20), 
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 50),
              ),
              const SizedBox(height: 15),
              const Text(
                "Unlock Premium!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Please deposit the fee to the bank account below and WhatsApp the payment receipt to unlock all app features.\n\nපහත බැංකු ගිණුමට මුදල් ගෙවා, ගෙවීම් ලදුපත WhatsApp කරන්න. ඉන්පසු ඇප් එකේ සියලුම පහසුකම් ලබාගත හැක!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Bank: Bank of Ceylon (BOC) / ලංකා බැංකුව", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    SizedBox(height: 5),
                    Text("Name: GK Quiz App", style: TextStyle(color: Colors.white70, fontSize: 13)),
                    SizedBox(height: 5),
                    Text("Account No: 1234567890", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.message, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text("WhatsApp: 07X XXX XXXX", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Got it!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedCategoryCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final String catId;
  final bool isNew;
  final bool isDisabled;

  const AnimatedCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.catId,
    this.isNew = false,
    this.isDisabled = false,
  });

  @override
  State<AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<AnimatedCategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _isHovered && !widget.isDisabled ? GradientBorderPainter(
              angle: _controller.value * 2 * math.pi,
              strokeWidth: 2.5,
              radius: 20,
              gradientColors: [
                const Color(0xFF38BDF8), 
                const Color(0xFFFF4757), 
                const Color(0xFF38BDF8), 
              ],
            ) : null,
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _isHovered && !widget.isDisabled ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04),
            border: Border.all(
              color: _isHovered && !widget.isDisabled ? Colors.transparent : Colors.white12,
              width: 1.0,
            ),
            boxShadow: [
              if (_isHovered && !widget.isDisabled)
                BoxShadow(
                  color: const Color(0xFF38BDF8).withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (widget.isDisabled) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Colors.white),
                          SizedBox(width: 10),
                          Text("Available Soon!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      backgroundColor: Colors.orangeAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    )
                  );
                } else {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => MainBackgroundWrapper(
                        child: PapersScreen(categoryId: widget.catId, categoryName: widget.title)
                      )
                    )
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(
                        color: _isHovered && !widget.isDisabled ? widget.iconColor.withOpacity(0.25) : widget.iconColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, size: 28, color: widget.isDisabled ? Colors.white38 : widget.iconColor),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            widget.title, 
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: widget.isDisabled ? Colors.white54 : Colors.white
                            ),
                          ),
                          if (widget.isNew) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(_isHovered && !widget.isDisabled ? 5 : 0, 0, 0),
                      child: Icon(
                        widget.isDisabled ? Icons.lock : Icons.arrow_forward_ios, 
                        size: widget.isDisabled ? 20 : 16, 
                        color: widget.isDisabled ? Colors.orangeAccent.withOpacity(0.8) : Colors.white24
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final double angle;
  final double strokeWidth;
  final double radius;
  final List<Color> gradientColors;

  GradientBorderPainter({
    required this.angle,
    required this.strokeWidth,
    required this.radius,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = SweepGradient(
        colors: gradientColors,
        transform: GradientRotation(angle),
      ).createShader(rect);

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) => 
      oldDelegate.angle != angle;
}