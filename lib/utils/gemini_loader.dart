import 'package:flutter/material.dart';
import 'dart:math' as math;

class GeminiLoader extends StatefulWidget {
  final double size;
  const GeminiLoader({super.key, this.size = 80});

  @override
  State<GeminiLoader> createState() => _GeminiLoaderState();
}

class _GeminiLoaderState extends State<GeminiLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: AstroBlackHolePainter(
                  rotation: _controller.value,
                  gradientColors: const [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                ),
              ),
            ),
            Transform.rotate(
              angle: -_controller.value * 2 * math.pi,
              child: Container(
                width: widget.size * 0.45,
                height: widget.size * 0.45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.white.withOpacity(0.02),
                    ],
                  ),
                  border: Border.all(color: Colors.white24, width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
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
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 8; i++) {
      final startAngle = rotation * 2 * math.pi + (i * 0.5 * math.pi);
      final currentRadius = radius - (i * 4);
      
      final rect = Rect.fromCircle(center: center, radius: currentRadius);
      paint.strokeWidth = 2.0 + (i * 0.5);
      paint.style = PaintingStyle.stroke;
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, 3 + (i * 0.5));
      
      canvas.drawArc(
        rect,
        startAngle,
        math.pi * 0.8,
        false,
        paint,
      );
    }

    final holePaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant AstroBlackHolePainter oldDelegate) => true;
}