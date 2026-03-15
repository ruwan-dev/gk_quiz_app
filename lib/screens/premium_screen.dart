import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:async';
import '../utils/app_constants.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _featureIndex = 0; 
  Timer? _autoPlayTimer;

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
      'enDesc': "Ability to view your rank. (This feature is for premium members only.)",
      'siDesc': "Ranking වල තමන්ට හිමි ස්ථානය බලාගැනිමට හැකිවීම.",
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
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchWhatsApp() async {
    final String phoneNumber = AppConstants.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final String finalPhone = phoneNumber.startsWith('0') ? '94${phoneNumber.substring(1)}' : phoneNumber;
    final String message = "Hi, I have made the payment for the Premium upgrade in the GK Quiz App. Please find my receipt attached.";
    final Uri url = Uri.parse("https://wa.me/$finalPhone?text=${Uri.encodeComponent(message)}");
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Could not launch $url';
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open WhatsApp.")));
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) setState(() => _featureIndex = (_featureIndex + 1) % _features.length);
    });
  }

  void _resetTimer() {
    _autoPlayTimer?.cancel();
    _startAutoPlay();
  }

  void _nextFeature() {
    _resetTimer();
    setState(() => _featureIndex = (_featureIndex + 1) % _features.length);
  }

  void _prevFeature() {
    _resetTimer();
    setState(() => _featureIndex = (_featureIndex - 1 + _features.length) % _features.length);
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
        Text(feature['title'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Text(feature['enDesc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
        const Padding(padding: EdgeInsets.symmetric(vertical: 12.0), child: Divider(color: Colors.white10, thickness: 1)),
        Text(feature['siDesc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _buildBankDetailRow(IconData icon, String label, String value, {bool canCopy = false, BuildContext? context}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 22),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Color(0xFF10B981), size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context!).showSnackBar(const SnackBar(content: Text("Copied!"), duration: Duration(seconds: 1)));
              },
            ),
        ],
      ),
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
          const Text("Upgrade to Premium", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Explore premium benefits", style: TextStyle(color: Color(0xFF38BDF8), fontSize: 13)),
          const SizedBox(height: 25),

          // 🚀 Animated Feature Card with Arrows
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) _prevFeature();
              else if (details.primaryVelocity! < 0) _nextFeature();
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
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 20),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(25)),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (Widget child, Animation<double> animation) => FadeTransition(opacity: animation, child: child),
                      child: _buildFeatureContent(_featureIndex),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF38BDF8), size: 20),
                          onPressed: _prevFeature,
                        ),
                        Row(
                          children: List.generate(_features.length, (index) => _buildDot(index)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF38BDF8), size: 20),
                          onPressed: _nextFeature,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 35),
          
          const Text("Payment Information", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                // 🚀 Limited Time Offer Banner eka me thanata genawa (Price ekata udin)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.15),
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "LIMITED TIME OFFER: UNTIL APRIL 30TH",
                        style: TextStyle(
                          color: Colors.orangeAccent, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w800, 
                          letterSpacing: 0.5
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.local_fire_department_rounded, color: Colors.orangeAccent, size: 16),
                    ],
                  ),
                ),
                
                // 🚀 Subscription Fee eka
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.08),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Subscription Fee", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(AppConstants.premiumPrice, style: const TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildBankDetailRow(Icons.account_balance_rounded, "BANK NAME", AppConstants.bankName),
                      const Divider(color: Colors.white10, height: 1),
                      _buildBankDetailRow(Icons.numbers_rounded, "ACCOUNT NUMBER", AppConstants.bankAccountNo, canCopy: true, context: context),
                      const Divider(color: Colors.white10, height: 1),
                      _buildBankDetailRow(Icons.person_outline_rounded, "ACCOUNT HOLDER", AppConstants.bankAccountName, canCopy: true, context: context),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),
          const Column(
            children: [
              Text("ගෙවීම් ලදුපත WhatsApp මගින් එවා ඔබගේ ගිණුම සක්‍රිය කරගන්න.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w500)),
              SizedBox(height: 5),
              Text("Send the payment receipt via WhatsApp to activate.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: _launchWhatsApp,
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text("WhatsApp Receipt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: _featureIndex == index ? 20 : 6,
      decoration: BoxDecoration(color: _featureIndex == index ? const Color(0xFF10B981) : Colors.white24, borderRadius: BorderRadius.circular(3)),
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
    final paint = Paint()..strokeWidth = strokeWidth..style = PaintingStyle.stroke..shader = SweepGradient(colors: gradientColors, transform: GradientRotation(angle)).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }
  @override
  bool shouldRepaint(covariant _PremiumGradientPainter oldDelegate) => oldDelegate.angle != angle;
}