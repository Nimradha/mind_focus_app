import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedStartButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const AnimatedStartButton({
    super.key,
    required this.onPressed,
    this.label = "Start",
  });

  @override
  State<AnimatedStartButton> createState() => _AnimatedStartButtonState();
}

class _AnimatedStartButtonState extends State<AnimatedStartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  // ── Color palette (blue ↔ green) ──
  static const Color _blue = Color(0xFF2979FF);
  static const Color _green = Color(0xFF00E676);
  static const Color _cyan = Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
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
      builder: (context, _) {
        final double t = _controller.value;
        final double angle = t * 2 * math.pi;

        // Moving glow offset (orbits around the button)
        final double glowX = math.cos(angle) * 5;
        final double glowY = math.sin(angle) * 3;

        // Gradient rotation for the border
        final double sweep = t * 2 * math.pi;

        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = false);
            widget.onPressed();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 1.06 : 1.0,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  // Primary orbiting glow (blue side)
                  BoxShadow(
                    color: _blue.withOpacity(_isPressed ? 0.55 : 0.35),
                    blurRadius: _isPressed ? 22 : 16,
                    spreadRadius: _isPressed ? 2 : 1,
                    offset: Offset(glowX, glowY),
                  ),
                  // Secondary orbiting glow (green side)
                  BoxShadow(
                    color: _green.withOpacity(_isPressed ? 0.50 : 0.30),
                    blurRadius: _isPressed ? 20 : 14,
                    spreadRadius: _isPressed ? 2 : 1,
                    offset: Offset(-glowX, -glowY),
                  ),
                  // Ambient glow
                  BoxShadow(
                    color: _cyan.withOpacity(_isPressed ? 0.25 : 0.12),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: _GradientBorderPainter(
                  sweepAngle: sweep,
                  isPressed: _isPressed,
                  blue: _blue,
                  green: _green,
                  cyan: _cyan,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    // When pressed → fill with gradient; default → dark
                    gradient: _isPressed
                        ? LinearGradient(
                            begin: Alignment(
                              math.cos(sweep),
                              math.sin(sweep),
                            ),
                            end: Alignment(
                              -math.cos(sweep),
                              -math.sin(sweep),
                            ),
                            colors: const [_blue, _cyan, _green],
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0xFF1A1A2E),
                              Color(0xFF16213E),
                            ],
                          ),
                  ),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints a rotating gradient border around the button.
class _GradientBorderPainter extends CustomPainter {
  final double sweepAngle;
  final bool isPressed;
  final Color blue;
  final Color green;
  final Color cyan;

  _GradientBorderPainter({
    required this.sweepAngle,
    required this.isPressed,
    required this.blue,
    required this.green,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(14));

    final gradient = SweepGradient(
      startAngle: sweepAngle,
      endAngle: sweepAngle + 2 * math.pi,
      colors: [blue, cyan, green, cyan, blue],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      tileMode: TileMode.clamp,
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isPressed ? 2.8 : 2.2;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter oldDelegate) => true;
}
