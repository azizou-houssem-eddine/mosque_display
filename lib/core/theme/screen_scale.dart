import 'package:flutter/widgets.dart';

/// Responsive screen scaling engine for TV displays (720p HD Ready, 1080p Full HD, 4K Ultra HD).
/// Calibrated for distant 10-15m mosque viewing readability without clipping across diverse
/// aspect ratios (16:9, 16:10, 4:3, 21:9).
class ScreenScale {
  final double width;
  final double height;
  final double customScale;

  const ScreenScale({
    required this.width,
    required this.height,
    this.customScale = 1.0,
  });

  factory ScreenScale.of(BuildContext context, {double? customScale}) {
    final size = MediaQuery.sizeOf(context);
    return ScreenScale(
      width: size.width,
      height: size.height,
      customScale: customScale ?? 1.0,
    );
  }

  /// Exact screen aspect ratio (width / height).
  double get aspectRatio => width / (height > 0 ? height : 1.0);

  /// Narrow aspect ratio (4:3, 5:4, vertical/square-ish displays).
  bool get isNarrow => aspectRatio < 1.50;

  /// Standard TV aspect ratio (16:10, 16:9).
  bool get isStandard => aspectRatio >= 1.50 && aspectRatio <= 1.85;

  /// Ultrawide aspect ratio (21:9, 32:9).
  bool get isUltrawide => aspectRatio > 1.85;

  /// Compact TV display (720p HD Ready / narrow or dense viewports).
  bool get isCompact => width <= 1366 || height < 750;

  /// Large TV display (4K Ultra HD / QHD, width >= 2560 or height >= 1440).
  bool get is4k => width >= 2560 || height >= 1440;

  /// Full HD display (1080p, standard TV baseline).
  bool get is1080p => !isCompact && !is4k;

  /// Pure geometric layout factor (Contain mode: min(scaleW, scaleH) * customScale).
  /// Guarantees ZERO physical layout overflow across any resolution or aspect ratio.
  double get layoutFactor {
    final scaleW = width / 1920.0;
    final scaleH = height / 1080.0;
    final base = (scaleW < scaleH ? scaleW : scaleH) * customScale;

    if (is4k) {
      return base.clamp(1.2 * customScale, 2.4 * customScale);
    }
    return base;
  }

  /// Distance-legibility typography factor.
  /// Maintains a minimum legibility floor for distant 10-15m viewing while respecting display boundaries.
  double get fontFactor {
    final geom = layoutFactor;
    if (isCompact) {
      return (geom * 1.08).clamp(0.65 * customScale, 1.15 * customScale);
    }
    return geom;
  }

  /// Proportionally scales a structural layout dimension (defined for 1080p) with optional bounds.
  double scaleLayout(double base1080p, {double? min, double? max}) {
    final val = base1080p * layoutFactor;
    if (min != null && val < min) return min;
    if (max != null && val > max) return max;
    return val;
  }

  /// Proportionally scales a typography font size (defined for 1080p) with optional bounds.
  double scaleFont(double base1080p, {double? min, double? max}) {
    final val = base1080p * fontFactor;
    if (min != null && val < min) return min;
    if (max != null && val > max) return max;
    return val;
  }

  /// Backward-compatible scaling factor: returns [layoutFactor].
  double get factor => layoutFactor;

  /// Backward-compatible scale method (delegates to [scaleLayout]).
  double scale(double base1080p, {double? min, double? max}) =>
      scaleLayout(base1080p, min: min, max: max);
}
