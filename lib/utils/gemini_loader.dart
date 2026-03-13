import 'package:flutter/material.dart';

class GeminiLoader extends StatefulWidget {
  final double size;
  const GeminiLoader({super.key, this.size = 50});

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
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 🌈 කැරකෙන දේදුනු වළල්ල (Gemini Style)
        RotationTransition(
          turns: _controller,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.blue,
                  Colors.purple,
                  Colors.pink,
                  Colors.orange,
                  Colors.cyan,
                  Colors.blue,
                ],
              ),
            ),
          ),
        ),
        // අයිකන් එක පේන්න මැද තියෙන අඳුරු කොටස
        Container(
          width: widget.size - 6,
          height: widget.size - 6,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A), 
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: widget.size * 0.5),
        ),
      ],
    );
  }
}