import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// Sacred 16-point Islamic geometric mandala rosette background watermark.
/// Drawn via CustomPainter — no external assets required.
class MandalaBackground extends StatelessWidget {
  final double opacity;

  const MandalaBackground({super.key, this.opacity = 0.07});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _MandalaPainter(opacity: opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _MandalaPainter extends CustomPainter {
  final double opacity;

  _MandalaPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) * 0.42;
    final paint = Paint()
      ..color = AppTheme.goldAccent.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw multiple concentric petal rings
    _drawPetalRing(canvas, centre, maxR, 16, paint);
    _drawPetalRing(canvas, centre, maxR * 0.72, 16, paint..strokeWidth = 0.8);
    _drawPetalRing(canvas, centre, maxR * 0.46, 8, paint..strokeWidth = 0.7);

    // Outer polygon frames
    _drawPolygon(canvas, centre, maxR * 1.02, 16, paint..strokeWidth = 0.6);
    _drawPolygon(canvas, centre, maxR * 0.78, 8, paint);

    // Centre star
    _drawStar(canvas, centre, maxR * 0.24, 8, paint..strokeWidth = 0.9);

    // Radiating lines
    final linePaint = Paint()
      ..color = AppTheme.goldAccent.withValues(alpha: opacity * 0.6)
      ..strokeWidth = 0.5;
    for (int i = 0; i < 16; i++) {
      final angle = i * math.pi / 8;
      canvas.drawLine(
        centre,
        Offset(
          centre.dx + math.cos(angle) * maxR,
          centre.dy + math.sin(angle) * maxR,
        ),
        linePaint,
      );
    }
  }

  void _drawPetalRing(
      Canvas canvas, Offset centre, double r, int count, Paint paint) {
    for (int i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count;
      final petalCx = centre.dx + r * 0.5 * math.cos(angle);
      final petalCy = centre.dy + r * 0.5 * math.sin(angle);
      canvas.drawCircle(Offset(petalCx, petalCy), r * 0.5, paint);
    }
  }

  void _drawPolygon(
      Canvas canvas, Offset centre, double r, int sides, Paint paint) {
    final path = Path();
    for (int i = 0; i <= sides; i++) {
      final angle = i * 2 * math.pi / sides - math.pi / 2;
      final x = centre.dx + r * math.cos(angle);
      final y = centre.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawStar(
      Canvas canvas, Offset centre, double r, int points, Paint paint) {
    final path = Path();
    final innerR = r * 0.45;
    for (int i = 0; i <= points * 2; i++) {
      final angle = i * math.pi / points - math.pi / 2;
      final radius = i.isEven ? r : innerR;
      final x = centre.dx + radius * math.cos(angle);
      final y = centre.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MandalaPainter old) => old.opacity != opacity;
}
