import 'package:flutter/material.dart';
import 'dart:math' as math;

class GeminiLoader extends StatefulWidget {
  final double size;
  const GeminiLoader({super.key, this.size = 100}); // Size එක පොඩ්ඩක් වැඩි කළා පැහැදිලි වෙන්න

  @override
  State<GeminiLoader> createState() => _GeminiLoaderState();
}

class _GeminiLoaderState extends State<GeminiLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _variableRotation;

  final List<IconData> _examIcons = [
    Icons.menu_book_rounded,
    Icons.timer_outlined,
    Icons.psychology_alt_rounded,
    Icons.edit_note_rounded,
    Icons.school_rounded,
    Icons.quiz_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Loop එක තත්පර 3කට කෙටි කළා Speed එක දැනෙන්න
    )..repeat();

    // 🚀 සරල කරකැවිල්ලක් වෙනුවට වේගය වෙනස් වන Animation එකක් හැදුවා
    _variableRotation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutQuart, // මේකෙන් තමයි "Speed -> Slow -> Speed" ලුක් එක එන්නේ
    );
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
        // Icon මාරු වෙන්න සාමාන්‍ය controller.value එක ගත්තා (ඒක smooth නිසා)
        int iconIndex = (_controller.value * _examIcons.length).floor();
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // 🚀 පිටත කැරකෙන ඉරි ටික (දැන් වේගය සරෙන් සැරේ වෙනස් වෙනවා)
            Transform.rotate(
              angle: _variableRotation.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: AstroBlackHolePainter(
                  rotation: _variableRotation.value,
                  gradientColors: [
                    const Color(0xFF10B981), // Green
                    Colors.amber.shade400,   // Gold
                    Colors.green.shade800,   // Dark Green
                    Colors.amber.shade700,   // Deep Gold
                    const Color(0xFF10B981),
                  ],
                ),
              ),
            ),
            
            // 🚀 මැද තියෙන Icon එක (දැන් කැපෙන්නේ නැහැ)
            SizedBox(
              width: widget.size * 0.4,
              height: widget.size * 0.4,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    _examIcons[iconIndex],
                    key: ValueKey<int>(iconIndex),
                    color: Colors.amber.shade500, 
                    size: widget.size * 0.3, // Icon size එක පොඩ්ඩක් Adjust කළා Gap එක තියන්න
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class AstroBlackHolePainter extends CustomPainter {
  final double rotation;
  final List<Color> gradientColors;

  AstroBlackHolePainter({required this.rotation, required this.gradientColors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..shader = SweepGradient(
        colors: gradientColors,
        startAngle: 0,
        endAngle: 2 * math.pi,
        transform: GradientRotation(rotation * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; 

    // 🚀 මෙතනදී ඇතුළතම රවුමේ Radius එක (i * 6) කරලා පරතරය වැඩි කළා
    // එතකොට Icon එකයි ඇතුළතම ඉරයි අතර හොඳ Gap එකක් තියෙනවා
    for (int i = 0; i < 5; i++) {
      final startAngle = (i * 0.4 * math.pi);
      final currentRadius = radius - (i * 7); // ඉරි අතර පරතරය වැඩි කළා
      
      // ඇතුළතම රවුම Icon එක උඩින් යන එක නවත්වන්න අවම සීමාවක් දැම්මා
      if (currentRadius < radius * 0.45) continue; 
      
      final rect = Rect.fromCircle(center: center, radius: currentRadius);
      paint.strokeWidth = 2.5; 
      
      canvas.drawArc(
        rect,
        startAngle,
        math.pi * 0.6, 
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant AstroBlackHolePainter oldDelegate) => true;
}