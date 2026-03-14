import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async'; // 🚀 Timer එක සඳහා අවශ්‍යයි
import '../utils/app_constants.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _featureIndex = 0; 
  Timer? _autoPlayTimer; // 🚀 Auto-swipe Timer එක

  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.lock_open_rounded,
      'title': "Access Premium Papers",
      'enDesc': "Unlock and practice all exclusive premium past papers and model papers.",
      'siDesc': "සියලුම අනුමාන ප්‍රශ්න පත්‍ර සඳහා පිවිසුම ලබාගන්න.",
    },
    {
      'icon': Icons.verified_rounded,
      'title': "Exclusive Verified Badge",
      'enDesc': "Stand out with a special verified badge next to your name.",
      'siDesc': "ඔබගේ නමට ඉදිරියෙන් සුවිශේෂී Verified ලාංඡනයක් (Badge) ලබාගන්න.",
    },
    {
      'icon': Icons.account_circle_rounded,
      'title': "Custom Profile Avatar",
      'enDesc': "Personalize your profile by uploading your own custom avatar.",
      'siDesc': "ඔබගේ ගිණුමට ඔබ කැමතිම පින්තූරයක් (Avatar) ඇතුළත් කරගන්න.",
    },
    {
      'icon': Icons.leaderboard_rounded,
      'title': "Leaderboard Visibility",
      'enDesc': "Ability to view your rank. (This feature does not affect your score, but the ranking/leaderboard will remain hidden.)",
      'siDesc': "Ranking වල තමන්ට හිමි ස්ථානය බලාගැනිමට හැකිවීම.(පහසුකම ලකුනු වලට බලපෑමක් සිදු නොකරයි,නමුත් Ranking එක නොපෙන්වයි)",
    },
    {
      'icon': Icons.ads_click_rounded,
      'title': "Ad-Free Experience",
      'enDesc': "Enjoy a smooth, uninterrupted learning experience without any ads.",
      'siDesc': "කිසිදු කරදරකාරී දැන්වීමකින් තොරව නිදහසේ ඇප් එක භාවිතා කරන්න.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _startAutoPlay(); // 🚀 Screen එක Load වෙද්දීම Timer එක පටන් ගන්නවා
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel(); // 🚀 Screen එකෙන් අයින් වෙද්දී Timer එක නවත්වනවා
    _controller.dispose();
    super.dispose();
  }

  // 🚀 තත්පර 10කට සැරයක් Feature එක මාරු කරන Function එක
  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _featureIndex = (_featureIndex + 1) % _features.length;
        });
      }
    });
  }

  // 🚀 User මැනුවල් Swipe කළොත් Timer එක Reset කරනවා
  void _resetTimer() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  void _nextFeature() {
    _resetTimer();
    setState(() {
      _featureIndex = (_featureIndex + 1) % _features.length;
    });
  }

  void _prevFeature() {
    _resetTimer();
    setState(() {
      _featureIndex = (_featureIndex - 1 + _features.length) % _features.length;
    });
  }

  Widget _buildFeatureContent(int index) {
    final feature = _features[index];

    return Column(
      key: ValueKey<int>(index), 
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(feature['icon'], color: Colors.amber, size: 60),
        ),
        const SizedBox(height: 25),
        
        Text(
          feature['title'],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        
        Text(
          feature['enDesc'],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12.0),
          child: Divider(color: Colors.white10, thickness: 1),
        ),

        Text(
          feature['siDesc'],
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          const Text(
            "Upgrade to Premium",
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Explore features (Auto-swiping)", 
            style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13),
          ),
          const SizedBox(height: 20),

          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                _prevFeature();
              } else if (details.primaryVelocity! < 0) {
                _nextFeature();
              }
            },
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => CustomPaint(
                painter: _PremiumGradientPainter(
                  angle: _controller.value * 2 * math.pi,
                  strokeWidth: 3.0,
                  radius: 25,
                  gradientColors: const [Color(0xFF10B981), Colors.amber, Color(0xFF059669), Colors.amber],
                ),
                child: child,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 600), // 🚀 Fade effect එකට කාලය වැඩි කළා
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: _buildFeatureContent(_featureIndex),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          color: const Color(0xFF38BDF8),
                          onPressed: _prevFeature,
                        ),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _features.length, 
                            (index) => _buildDot(index)
                          ),
                        ),
                        
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded),
                          color: const Color(0xFF38BDF8),
                          onPressed: _nextFeature,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          const Text(
            "Ready to Upgrade?",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Please deposit the fee and WhatsApp the payment receipt to unlock all app features.\n\nපහත බැංකු ගිණුමට මුදල් ගෙවා ලදුපත WhatsApp කරන්න.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bank: ${AppConstants.bankName}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                Text("Account No: ${AppConstants.bankAccountNo}", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Text("Name: ${AppConstants.bankAccountName}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                  child: Divider(color: Colors.white10, thickness: 1),
                ),
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366), size: 20),
                    const SizedBox(width: 10),
                    Text("WhatsApp: ${AppConstants.phoneNumber}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: _featureIndex == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _featureIndex == index ? const Color(0xFF10B981) : Colors.white24,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _PremiumGradientPainter extends CustomPainter {
  final double angle, strokeWidth, radius;
  final List<Color> gradientColors;

  _PremiumGradientPainter({required this.angle, required this.strokeWidth, required this.radius, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..shader = SweepGradient(colors: gradientColors, transform: GradientRotation(angle)).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _PremiumGradientPainter oldDelegate) => oldDelegate.angle != angle;
}