import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// Segmented & continuous radiant gold circular countdown gauge.
/// Designed for high-contrast mosque displays (visible from 15+ meters).
/// Features precision astrolabe ticks, glowing gold progress arc,
/// radiant head cursor jewel, etched Islamic rosette dial, and crisp typography.
class CircularGaugeWidget extends StatefulWidget {
  /// Current elapsed / remaining ratio [0.0 – 1.0].
  final double progress;

  /// Label shown in the centre (e.g. "12:31" or "02:45:30").
  final String centerLabel;

  /// Subtitle below centre label (e.g. "حتى الإقامة").
  final String? subtitle;

  /// Outer diameter of the gauge.
  final double size;

  /// Number of segments / ticks in the ring.
  final int segments;

  /// Show pulsing glow animation when [progress] > 0.98.
  final bool pulseOnComplete;

  const CircularGaugeWidget({
    super.key,
    required this.progress,
    required this.centerLabel,
    this.subtitle,
    this.size = 360,
    this.segments = 60,
    this.pulseOnComplete = true,
  });

  @override
  State<CircularGaugeWidget> createState() => _CircularGaugeWidgetState();
}

class _CircularGaugeWidgetState extends State<CircularGaugeWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPulsing = widget.pulseOnComplete && widget.progress >= 0.98;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, child) {
        final glowScale = isPulsing ? _pulseAnim.value : 1.0;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Ambient radiant golden background halo
              Container(
                width: widget.size * 0.96,
                height: widget.size * 0.96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(
                        alpha: (0.28 * glowScale).clamp(0.0, 0.7),
                      ),
                      blurRadius: 55 * glowScale,
                      spreadRadius: 8,
                    ),
                    BoxShadow(
                      color: AppTheme.emeraldLight.withValues(alpha: 0.15),
                      blurRadius: 75,
                      spreadRadius: 15,
                    ),
                  ],
                ),
              ),

              // Custom Astrolabe & Gauge Painter
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _LuxuryGaugePainter(
                  progress: widget.progress.clamp(0.0, 1.0),
                  pulseGlow: glowScale,
                ),
              ),

              // Centre Display Content
              Padding(
                padding: EdgeInsets.symmetric(horizontal: widget.size * 0.12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Small elegant top label
                    Text(
                      'الوَقْتُ المُتَبَقِّي',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: (widget.size * 0.048).clamp(12.0, 32.0),
                        color: AppTheme.goldDim.withValues(alpha: 0.90),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 2),

                    // Big digital countdown clock
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.centerLabel,
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: widget.size * 0.21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: (widget.size * 0.006).clamp(1.5, 4.0),
                          shadows: [
                            Shadow(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.70),
                              blurRadius: (widget.size * 0.05).clamp(12.0, 36.0),
                            ),
                            Shadow(
                              color: Colors.black87,
                              blurRadius: (widget.size * 0.035).clamp(8.0, 24.0),
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Subtitle in an illuminated royal pill badge
                    if (widget.subtitle != null) ...[
                      SizedBox(height: (widget.size * 0.016).clamp(4.0, 12.0)),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: (widget.size * 0.048).clamp(10.0, 36.0),
                          vertical: (widget.size * 0.012).clamp(3.0, 10.0),
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.goldDim.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.85),
                            width: (widget.size * 0.0035).clamp(1.0, 2.5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldPrimary.withValues(alpha: 0.25),
                              blurRadius: (widget.size * 0.03).clamp(8.0, 22.0),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.subtitle!,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: (widget.size * 0.056).clamp(13.0, 36.0),
                            color: AppTheme.goldPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LuxuryGaugePainter extends CustomPainter {
  final double progress;
  final double pulseGlow;

  _LuxuryGaugePainter({
    required this.progress,
    required this.pulseGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 10;
    final trackWidth = outerRadius * 0.125;
    final trackCenterRadius = outerRadius - trackWidth / 2 - 8;
    final innerDialRadius = trackCenterRadius - trackWidth / 2 - 4;

    // ── 1. Outer Fine Gold Ring ──────────────────────────────────────────────
    final outerRingPaint = Paint()
      ..color = AppTheme.goldDim.withValues(alpha: 0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerRadius * 0.006).clamp(1.5, 3.5);
    canvas.drawCircle(centre, outerRadius, outerRingPaint);

    // ── 2. Astrolabe Graduation Tick Marks (60 ticks & 4 Cardinal Fleurons) ─
    final cardinalTick = outerRadius * 0.075;
    final majorTick = outerRadius * 0.052;
    final minorTick = outerRadius * 0.030;

    for (int i = 0; i < 60; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 60);
      final isCardinal = (i % 15 == 0);
      final isMajor = (i % 5 == 0);
      final tickLen = isCardinal ? cardinalTick : isMajor ? majorTick : minorTick;
      final p1 = Offset(
        centre.dx + outerRadius * math.cos(angle),
        centre.dy + outerRadius * math.sin(angle),
      );
      final p2 = Offset(
        centre.dx + (outerRadius - tickLen) * math.cos(angle),
        centre.dy + (outerRadius - tickLen) * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = isCardinal
            ? AppTheme.goldLight
            : isMajor
                ? AppTheme.goldPrimary.withValues(alpha: 0.9)
                : AppTheme.goldDim.withValues(alpha: 0.38)
        ..strokeWidth = isCardinal
            ? (outerRadius * 0.016).clamp(2.5, 6.0)
            : isMajor
                ? (outerRadius * 0.012).clamp(1.8, 4.5)
                : (outerRadius * 0.007).clamp(1.0, 2.5);
      canvas.drawLine(p1, p2, tickPaint);

      // Draw diamond jewel at 4 cardinal axes
      if (isCardinal) {
        final dR = (outerRadius * 0.024).clamp(3.0, 8.0);
        final diamondCenter = Offset(
          centre.dx + (outerRadius + dR * 0.8) * math.cos(angle),
          centre.dy + (outerRadius + dR * 0.8) * math.sin(angle),
        );
        final diamondPath = Path();
        diamondPath.moveTo(diamondCenter.dx, diamondCenter.dy - dR);
        diamondPath.lineTo(diamondCenter.dx + dR, diamondCenter.dy);
        diamondPath.lineTo(diamondCenter.dx, diamondCenter.dy + dR);
        diamondPath.lineTo(diamondCenter.dx - dR, diamondCenter.dy);
        diamondPath.close();

        final diamondPaint = Paint()
          ..color = AppTheme.goldPrimary
          ..style = PaintingStyle.fill;
        canvas.drawPath(diamondPath, diamondPaint);
      }
    }

    // ── 3. Background Track Channel ──────────────────────────────────────────
    final bgTrackPaint = Paint()
      ..color = const Color(0xFF041E15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = trackWidth;
    canvas.drawCircle(centre, trackCenterRadius, bgTrackPaint);

    // Track outer and inner boundary metallic strokes
    final borderPaint = Paint()
      ..color = AppTheme.goldDim.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (outerRadius * 0.005).clamp(1.0, 2.2);
    canvas.drawCircle(centre, trackCenterRadius + trackWidth / 2, borderPaint);
    canvas.drawCircle(centre, trackCenterRadius - trackWidth / 2, borderPaint);

    // ── 4. Inner Dial Disc (Velvety Emerald Radial Face) ─────────────────────
    final dialRect = Rect.fromCircle(center: centre, radius: innerDialRadius);
    final dialBgPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFF0F3E2E),
          Color(0xFF08261C),
          Color(0xFF02130C),
        ],
        stops: [0.0, 0.65, 1.0],
      ).createShader(dialRect);
    canvas.drawCircle(centre, innerDialRadius, dialBgPaint);

    // ── 5. Etched Islamic 16-point Geometric Rosette Watermark ───────────────
    final rosettePaint = Paint()
      ..color = AppTheme.goldPrimary.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (innerDialRadius * 0.007).clamp(0.8, 2.0);

    // Concentric guide circles
    canvas.drawCircle(centre, innerDialRadius * 0.45, rosettePaint);
    canvas.drawCircle(centre, innerDialRadius * 0.72, rosettePaint);

    // Intersecting 16-star rays
    for (int i = 0; i < 16; i++) {
      final a = i * (math.pi / 8);
      final rInner = innerDialRadius * 0.22;
      final rOuter = innerDialRadius * 0.72;
      canvas.drawLine(
        Offset(centre.dx + rInner * math.cos(a), centre.dy + rInner * math.sin(a)),
        Offset(centre.dx + rOuter * math.cos(a), centre.dy + rOuter * math.sin(a)),
        rosettePaint,
      );
    }

    // Overlapping 8-point geometric star (Rub el Hizb)
    final starR = innerDialRadius * 0.45;
    for (int s = 0; s < 2; s++) {
      final rot = s * (math.pi / 4);
      final starPath = Path();
      for (int k = 0; k < 4; k++) {
        final a = rot + k * (math.pi / 2);
        final x = centre.dx + starR * math.cos(a);
        final y = centre.dy + starR * math.sin(a);
        if (k == 0) {
          starPath.moveTo(x, y);
        } else {
          starPath.lineTo(x, y);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, rosettePaint);
    }

    // Inner Dial Bezel Stroke
    final innerBezelPaint = Paint()
      ..color = AppTheme.goldPrimary.withValues(alpha: 0.70)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (innerDialRadius * 0.012).clamp(1.8, 3.8);
    canvas.drawCircle(centre, innerDialRadius, innerBezelPaint);

    // ── 6. Active Radiant Progress Arc ───────────────────────────────────────
    if (progress > 0.005) {
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      // Outer golden bloom glow
      final bloomPaint = Paint()
        ..color = AppTheme.goldPrimary.withValues(alpha: 0.45 * pulseGlow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackWidth * 1.30
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, (trackWidth * 0.35).clamp(6.0, 22.0));
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: trackCenterRadius),
        startAngle,
        sweepAngle,
        false,
        bloomPaint,
      );

      // Solid luminous golden arc with sweep gradient
      const sweepGradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + 2 * math.pi,
        colors: [
          Color(0xFFFFF9C4), // Brilliant champagne gold
          Color(0xFFF2C94C), // Radiant royal gold
          Color(0xFFD4AF37), // Warm antique gold
          Color(0xFFFFA000), // Deep amber gold
          Color(0xFFF2C94C),
        ],
        stops: [0.0, 0.25, 0.6, 0.85, 1.0],
        transform: GradientRotation(startAngle),
      );

      final arcPaint = Paint()
        ..shader = sweepGradient.createShader(
            Rect.fromCircle(center: centre, radius: trackCenterRadius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = trackWidth * 0.88
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: trackCenterRadius),
        startAngle,
        sweepAngle,
        false,
        arcPaint,
      );

      // ── 7. Radiant Head Jewel (Cursor at leading edge) ─────────────────────
      final headAngle = startAngle + sweepAngle;
      final headX = centre.dx + trackCenterRadius * math.cos(headAngle);
      final headY = centre.dy + trackCenterRadius * math.sin(headAngle);
      final headCenter = Offset(headX, headY);

      // Glowing outer aura
      final jewelAura = Paint()
        ..color = AppTheme.goldLight.withValues(alpha: 0.70 * pulseGlow)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, (trackWidth * 0.35).clamp(5.0, 20.0));
      canvas.drawCircle(headCenter, trackWidth * 0.75, jewelAura);

      // Bright white-gold core
      final jewelCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headCenter, trackWidth * 0.40, jewelCore);

      // Gold rim around core
      final jewelRim = Paint()
        ..color = AppTheme.goldPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = (trackWidth * 0.08).clamp(1.8, 4.0);
      canvas.drawCircle(headCenter, trackWidth * 0.40, jewelRim);
    }
  }

  @override
  bool shouldRepaint(_LuxuryGaugePainter old) =>
      old.progress != progress || old.pulseGlow != pulseGlow;
}

