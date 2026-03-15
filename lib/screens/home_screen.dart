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
import 'premium_screen.dart'; 
import '../main.dart';
import '../theme/app_theme.dart';
import '../utils/gemini_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentLabel = "Home";

  Widget _getScreen(bool isAdmin) {
    switch (_currentLabel) {
      case "Home": 
        return HomeTab(onNavigate: _onNavigateToTab); 
      case "Rank": 
        return LeaderboardScreen(onNavigate: _onNavigateToTab); 
      case "Premium": 
        return const PremiumScreen(); 
      case "Profile": 
        return const ProfileScreen();
      case "Admin": 
        return isAdmin ? const AdminPanel() : HomeTab(onNavigate: _onNavigateToTab);
      default: 
        return HomeTab(onNavigate: _onNavigateToTab);
    }
  }

  void _onNavigateToTab(String label) {
    setState(() {
      _currentLabel = label;
    });
  }

  void _onItemTapped(String label, bool isDeactivated, BuildContext context) {
    if (isDeactivated) {
      _showDeactivatedSnackBar();
      return;
    }
    if (label == "Logout") {
      _showLogoutDialog();
      return;
    }
    
    setState(() {
      _currentLabel = label;
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
        bool isPremium = false;
        
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          isDeactivated = data?['isDeactivated'] ?? false;
          isPremium = data?['isPremium'] ?? false;
        }

        List<BottomNavigationBarItem> navItems = [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: "Rank"),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ];

        if (!isPremium) {
          navItems.add(const BottomNavigationBarItem(icon: AnimatedPremiumIcon(), label: "Premium"));
        }

        if (isAdmin) {
          navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin"));
        }

        navItems.add(const BottomNavigationBarItem(icon: Icon(Icons.logout, color: Colors.redAccent), label: "Logout"));

        int currentIndex = navItems.indexWhere((item) => item.label == _currentLabel);
        if (currentIndex == -1) currentIndex = 0;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea( 
            child: Column(
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
                      child: _getScreen(isAdmin),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white12, width: 1))),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: isDeactivated ? Colors.white24 : const Color(0xFF38BDF8),
              unselectedItemColor: Colors.white24,
              currentIndex: currentIndex,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              onTap: (index) => _onItemTapped(navItems[index].label ?? "", isDeactivated, context),
              items: navItems,
            ),
          ),
        );
      },
    );
  }
}

class AnimatedPremiumIcon extends StatefulWidget {
  const AnimatedPremiumIcon({super.key});
  @override
  State<AnimatedPremiumIcon> createState() => _AnimatedPremiumIconState();
}

class _AnimatedPremiumIconState extends State<AnimatedPremiumIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => SweepGradient(
            colors: const [Colors.amber, Colors.orangeAccent, Color(0xFF10B981), Colors.amber],
            transform: GradientRotation(_controller.value * 2 * math.pi),
          ).createShader(bounds),
          child: const Icon(Icons.workspace_premium, color: Colors.white),
        );
      }
    );
  }
}

class HomeTab extends StatefulWidget {
  final Function(String) onNavigate; 
  const HomeTab({super.key, required this.onNavigate});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  late AnimationController _borderController;

  @override
  void initState() {
    super.initState();
    _borderController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _borderController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 25), 
          
          Center(
            child: Image.asset(
              'assets/logo.png', // 🚀 ලෝගෝ එක මෙතන තියෙනවා
              width: 100,
              height: 100,
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 80);
              if (!snapshot.hasData) return const SizedBox(height: 80);
              var userData = snapshot.data!.data() as Map<String, dynamic>?;
              String name = userData?['name'] ?? currentUser?.email?.split('@')[0] ?? 'User';
              int score = userData?['totalScore'] ?? 0;
              bool isPremium = userData?['isPremium'] ?? false;

              return AnimatedBuilder(
                animation: _borderController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: GradientBorderPainter(
                      angle: _borderController.value * 2 * math.pi,
                      strokeWidth: 2,
                      radius: 30,
                      gradientColors: [const Color(0xFF38BDF8), const Color(0xFF6366F1), const Color(0xFF38BDF8)],
                    ),
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
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
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () => widget.onNavigate("Premium"), 
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
                                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), shape: BoxShape.circle),
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
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 35),
          const Text("Select Category", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('categories')
                .orderBy('createdAt', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.only(top: 40.0), child: GeminiLoader(size: 60)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No categories found", style: TextStyle(color: Colors.white70)));
              }

              final visibleCategories = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !(data.containsKey('isVisible') && data['isVisible'] == false);
              }).toList();

              visibleCategories.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                bool isNewA = dataA['isNew'] ?? false;
                bool isNewB = dataB['isNew'] ?? false;
                if (isNewA && !isNewB) return -1;
                if (!isNewA && isNewB) return 1;
                return 0; 
              });

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), 
                padding: const EdgeInsets.only(bottom: 20),
                itemCount: visibleCategories.length,
                itemBuilder: (context, index) {
                  final data = visibleCategories[index].data() as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: AnimatedCategoryCard(
                      title: data['name'],
                      icon: IconHelper.getIcon(data['iconKey']),
                      iconColor: const Color(0xFF38BDF8),
                      catId: data['id'],
                      isNew: data['isNew'] ?? false,
                      isDisabled: data['isDisabled'] ?? false,
                      onNavigate: widget.onNavigate,
                    ),
                  );
                },
              );
            },
          ),
        ],
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
  final Function(String) onNavigate;

  const AnimatedCategoryCard({
    super.key, 
    required this.title, 
    required this.icon, 
    required this.iconColor, 
    required this.catId, 
    this.isNew = false, 
    this.isDisabled = false,
    required this.onNavigate,
  });
  
  @override
  State<AnimatedCategoryCard> createState() => _AnimatedCategoryCardState();
}

class _AnimatedCategoryCardState extends State<AnimatedCategoryCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller; bool _isHovered = false;
  
  @override
  void initState() { 
    super.initState(); 
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(); 
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  Widget _buildAnimatedLabel(String text, List<Color> colors, Color shadowColor) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, _controller.value, (_controller.value + 0.1).clamp(0.0, 1.0), 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 0.5
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true), onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => CustomPaint(
          painter: _isHovered && !widget.isDisabled 
              ? GradientBorderPainter(angle: _controller.value * 2 * math.pi, strokeWidth: 2.5, radius: 20, gradientColors: [const Color(0xFF38BDF8), const Color(0xFFFF4757), const Color(0xFF38BDF8)]) 
              : null, 
          child: child
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), 
            color: _isHovered && !widget.isDisabled ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.04), 
            border: Border.all(color: _isHovered && !widget.isDisabled ? Colors.transparent : Colors.white12, width: 1.0)
          ),
          child: Material(
            color: Colors.transparent, 
            borderRadius: BorderRadius.circular(20), 
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                if (!widget.isDisabled) {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => MainBackgroundWrapper(
                        child: PapersScreen(
                          categoryId: widget.catId, 
                          categoryName: widget.title,
                          onNavigate: widget.onNavigate,
                        )
                      )
                    )
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0), 
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center, // අයිකනය මැදට තබා ගැනීම
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(color: _isHovered && !widget.isDisabled ? widget.iconColor.withOpacity(0.25) : widget.iconColor.withOpacity(0.1), shape: BoxShape.circle), 
                      child: Icon(widget.icon, size: 28, color: widget.isDisabled ? Colors.white38 : widget.iconColor)
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🚀 නම පේළි දෙකකට යාමට ඉඩ දීම
                          Text(
                            widget.title, 
                            maxLines: 2, 
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: widget.isDisabled ? Colors.white54 : Colors.white,
                              height: 1.2, // පේළි දෙක අතර පරතරය පාලනයට
                            ),
                          ),
                          
                          // 🚀 ලේබල් එක නමට යටින් පෙන්වීම (නම දිග වුවහොත් පිරිසිදුව පෙනේ)
                          if ((widget.isNew && !widget.isDisabled) || widget.isDisabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  if (widget.isNew && !widget.isDisabled)
                                    _buildAnimatedLabel(
                                      "NEW", 
                                      [const Color(0xFF10B981), const Color(0xFF34D399), const Color(0xFF059669), const Color(0xFF10B981)],
                                      const Color(0xFF10B981)
                                    ),
                                  
                                  if (widget.isDisabled)
                                    _buildAnimatedLabel(
                                      "SOON", 
                                      [Colors.orangeAccent, Colors.amber, Colors.deepOrangeAccent, Colors.orangeAccent],
                                      Colors.orangeAccent
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(widget.isDisabled ? Icons.lock : Icons.arrow_forward_ios, size: 16, color: Colors.white24),
                  ]
                )
              ),
            )
          ),
        ),
      ),
    );
  }
}

class GradientBorderPainter extends CustomPainter {
  final double angle, strokeWidth, radius; final List<Color> gradientColors;
  GradientBorderPainter({required this.angle, required this.strokeWidth, required this.radius, required this.gradientColors});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()..strokeWidth = strokeWidth..style = PaintingStyle.stroke..shader = SweepGradient(colors: gradientColors, transform: GradientRotation(angle)).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(covariant GradientBorderPainter oldDelegate) => oldDelegate.angle != angle;
}