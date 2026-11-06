import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';

/// Individual prayer time card used on the Main Dashboard.
/// Shows prayer name (Arabic), time, and highlights when active/next.
/// Optimized for 10-15 meter distant viewing across large prayer halls.
class PrayerCardWidget extends StatelessWidget {
  final String prayerNameAr;
  final String time; // "HH:MM"
  final bool isActive; // Currently in progress (illuminated royal gold)
  final bool isNext; // Next upcoming prayer (warm gold accent highlight)
  final bool isFocused; // D-pad focus
  final double? width;
  final String? auxiliaryLabel; // e.g. "الإمساك" or "الإفطار"
  final String? auxiliaryTime; // e.g. "05:12"
  final ThemePalette? palette;

  const PrayerCardWidget({
    super.key,
    required this.prayerNameAr,
    required this.time,
    this.isActive = false,
    this.isNext = false,
    this.isFocused = false,
    this.width,
    this.auxiliaryLabel,
    this.auxiliaryTime,
    this.palette,
  });

  @override
  Widget build(BuildContext context) {
    double? customScale;
    try {
      customScale = Provider.of<DisplayProvider>(context).settings.uiScaleFactor;
    } catch (_) {
      customScale = null;
    }
    final scale = ScreenScale.of(context, customScale: customScale);
    final cardWidth = width ?? scale.scaleLayout(250, min: 180, max: 540);
    final badgeHeight = scale.scaleLayout(24, min: 18, max: 40);

    final goldPrimary = palette?.goldPrimary ?? AppTheme.goldPrimary;
    final goldAccent = palette?.goldAccent ?? AppTheme.goldAccent;
    final goldDim = palette?.goldDim ?? AppTheme.goldDim;
    final goldLight = palette?.goldLight ?? AppTheme.goldLight;
    final cardGradient = palette?.cardGradient ?? AppTheme.cardGradient;
    final cardActiveGradient =
        palette?.cardActiveGradient ?? AppTheme.cardActiveGradient;
    final cardNextGradient =
        palette?.cardNextGradient ?? AppTheme.cardNextGradient;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: cardWidth,
      constraints: BoxConstraints(
        minWidth: scale.scaleLayout(120, min: 70),
        maxWidth: scale.is4k ? 600 : (scale.isCompact ? 260 : 360),
      ),
      padding: EdgeInsets.symmetric(
        vertical: scale.scale(13, min: 8, max: 26),
        horizontal: scale.scale(12, min: 8, max: 22),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
        gradient: isActive
            ? cardActiveGradient
            : isNext
                ? cardNextGradient
                : cardGradient,
        border: Border.all(
          color: isFocused
              ? AppTheme.focusBorder
              : isActive
                  ? goldPrimary
                  : isNext
                      ? goldAccent.withValues(alpha: 0.90)
                      : goldDim.withValues(alpha: 0.25),
          width: isFocused
              ? 3.0
              : isActive
                  ? scale.scale(2.2, min: 1.8, max: 4.0)
                  : isNext
                      ? scale.scale(1.8, min: 1.4, max: 3.2)
                      : 1.0,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: goldPrimary.withValues(alpha: 0.45),
              blurRadius: scale.scale(22, min: 16, max: 40),
              spreadRadius: 2,
            )
          else if (isActive)
            BoxShadow(
              color: goldPrimary.withValues(alpha: 0.35),
              blurRadius: scale.scale(24, min: 16, max: 44),
              spreadRadius: 2,
            )
          else if (isNext)
            BoxShadow(
              color: goldAccent.withValues(alpha: 0.24),
              blurRadius: scale.scale(18, min: 12, max: 32),
              spreadRadius: 1,
            )
          else
            const BoxShadow(
              color: Colors.black38,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Uniform-height top status badge area (keeps prayer names perfectly aligned across all cards)
          SizedBox(
            height: badgeHeight,
            child: Center(
              child: isActive
                  ? Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.scale(10, min: 8, max: 18),
                        vertical: scale.scale(2, min: 1, max: 4),
                      ),
                      decoration: BoxDecoration(
                        color: goldPrimary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: goldPrimary.withValues(alpha: 0.85),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: goldPrimary.withValues(alpha: 0.20),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            size: scale.scale(11, min: 9, max: 18),
                            color: goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: scale.scale(12, min: 10, max: 20),
                              fontWeight: FontWeight.bold,
                              color: goldPrimary,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    )
                  : isNext
                      ? Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: scale.scale(10, min: 8, max: 18),
                            vertical: scale.scale(2, min: 1, max: 4),
                          ),
                          decoration: BoxDecoration(
                            color: goldAccent.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.80),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: goldAccent.withValues(alpha: 0.16),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '✦',
                                style: TextStyle(
                                  color: goldLight,
                                  fontSize: scale.scale(11, min: 9, max: 18),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'القادمة',
                                style: TextStyle(
                                  fontFamily: 'Cairo',
                                  fontSize: scale.scale(12, min: 10, max: 20),
                                  fontWeight: FontWeight.bold,
                                  color: goldLight,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          '✦',
                          style: TextStyle(
                            color: goldDim.withValues(alpha: 0.30),
                            fontSize: scale.scale(10, min: 8, max: 16),
                          ),
                        ),
            ),
          ),
          SizedBox(height: scale.scale(4, min: 2, max: 8)),

          // Prayer Name
          Text(
            prayerNameAr,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(23, min: 18, max: 44),
              fontWeight: isActive
                  ? FontWeight.w800
                  : isNext
                      ? FontWeight.w700
                      : FontWeight.w600,
              color: isActive
                  ? goldPrimary
                  : isNext
                      ? goldLight
                      : AppTheme.textPrimary,
              shadows: [
                if (isActive)
                  Shadow(
                    color: goldPrimary.withValues(alpha: 0.55),
                    blurRadius: scale.scale(12, min: 8, max: 20),
                  )
                else if (isNext)
                  Shadow(
                    color: goldLight.withValues(alpha: 0.40),
                    blurRadius: scale.scale(10, min: 6, max: 16),
                  )
                else
                  const Shadow(
                    color: Colors.black54,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
              ],
            ),
            textDirection: TextDirection.rtl,
          ),
          if (prayerNameAr == 'الجمعة')
            Text(
              'الظهر',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: scale.scale(12, min: 9, max: 18),
                color: goldDim.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),

          // Delicate Islamic arched divider
          Container(
            margin: EdgeInsets.symmetric(vertical: scale.scale(5, min: 3, max: 10)),
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isActive
                      ? goldPrimary.withValues(alpha: 0.8)
                      : isNext
                          ? goldAccent.withValues(alpha: 0.6)
                          : goldDim.withValues(alpha: 0.22),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Time digits (Ultra high contrast, tabular spacing for distant TV viewing)
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(38, min: 28, max: 72),
              fontWeight: FontWeight.w800,
              letterSpacing: scale.scale(1.6, min: 1.0, max: 2.8),
              color: isActive
                  ? goldPrimary
                  : isNext
                      ? goldLight
                      : Colors.white,
              shadows: [
                if (isActive)
                  Shadow(
                    color: goldPrimary.withValues(alpha: 0.65),
                    blurRadius: scale.scale(16, min: 10, max: 28),
                  )
                else if (isNext)
                  Shadow(
                    color: goldAccent.withValues(alpha: 0.50),
                    blurRadius: scale.scale(14, min: 8, max: 24),
                  ),
                const Shadow(
                  color: Colors.black87,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          if (auxiliaryLabel != null && auxiliaryTime != null) ...[
            SizedBox(height: scale.scale(4, min: 2, max: 8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(8, min: 6, max: 14),
                vertical: scale.scale(2, min: 1, max: 4),
              ),
              decoration: BoxDecoration(
                color: palette?.bgDeep.withValues(alpha: 0.8) ??
                    AppTheme.emeraldDeep.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(scale.scale(8, min: 6, max: 12)),
                border: Border.all(
                  color: goldPrimary.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auxiliaryLabel!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(12, min: 10, max: 18),
                        color: goldLight,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      auxiliaryTime!,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: scale.scale(13, min: 11, max: 20),
                        color: goldPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
}
