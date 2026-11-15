import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Futuristic SINRAS PRO Hologram / Arc Reactor Voice Visualizer HUD.
class JarvisHudWidget extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final bool isThinking;
  final VoidCallback onTap;

  const JarvisHudWidget({
    super.key,
    required this.isListening,
    required this.isSpeaking,
    required this.isThinking,
    required this.onTap,
  });

  @override
  State<JarvisHudWidget> createState() => _JarvisHudWidgetState();
}

class _JarvisHudWidgetState extends State<JarvisHudWidget>
    with SingleTickerProviderStateMixin {
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
    final isAcive = widget.isListening || widget.isSpeaking || widget.isThinking;

    final primaryColor = widget.isListening
        ? const Color(0xFFFF3B30) // Red when recording
        : widget.isThinking
            ? const Color(0xFFFF9500) // Amber when thinking
            : const Color(0xFF00E5FF); // Cyan Blue by default

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final rotation = _controller.value * 2 * math.pi;

          return SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulse Ring
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isAcive ? 150 : 130,
                  height: isAcive ? 150 : 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withAlpha(isAcive ? 180 : 80),
                        blurRadius: isAcive ? 35 : 15,
                        spreadRadius: isAcive ? 10 : 3,
                      ),
                    ],
                  ),
                ),

                // Rotating Tech Ring
                Transform.rotate(
                  angle: rotation,
                  child: CustomPaint(
                    size: const Size(140, 140),
                    painter: _HudRingPainter(color: primaryColor),
                  ),
                ),

                // Counter-Rotating Inner Ring
                Transform.rotate(
                  angle: -rotation * 1.5,
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: _HudInnerPainter(color: primaryColor),
                  ),
                ),

                // Core Arc Reactor Mic Button
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryColor,
                        primaryColor.withAlpha(150),
                        Colors.black,
                      ],
                    ),
                    border: Border.all(
                      color: primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.isListening
                        ? Icons.graphic_eq_rounded
                        : widget.isThinking
                            ? Icons.psychology_rounded
                            : Icons.mic_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HudRingPainter extends CustomPainter {
  final Color color;
  _HudRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * math.pi / 180;
      final x1 = center.dx + (radius - 8) * math.cos(angle);
      final y1 = center.dy + (radius - 8) * math.sin(angle);
      final x2 = center.dx + radius * math.cos(angle);
      final y2 = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HudRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HudInnerPainter extends CustomPainter {
  final Color color;
  _HudInnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(160)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawArc(rect, 0, math.pi / 2, false, paint);
    canvas.drawArc(rect, math.pi, math.pi / 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _HudInnerPainter oldDelegate) =>
      oldDelegate.color != color;
}
