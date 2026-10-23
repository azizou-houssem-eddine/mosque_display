import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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

  const PrayerCardWidget({
    super.key,
    required this.prayerNameAr,
    required this.time,
    this.isActive = false,
    this.isNext = false,
    this.isFocused = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final scale = ScreenScale.of(context);
    final cardWidth = width ?? scale.scale(250, min: 180, max: 540);
    final badgeHeight = scale.scale(24, min: 18, max: 40);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: cardWidth,
      constraints: BoxConstraints(
        minWidth: 160,
        maxWidth: scale.is4k ? 600 : (scale.isCompact ? 220 : 360),
      ),
      padding: EdgeInsets.symmetric(
        vertical: scale.scale(13, min: 8, max: 26),
        horizontal: scale.scale(12, min: 8, max: 22),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
        gradient: isActive
            ? AppTheme.cardActiveGradient
            : isNext
                ? AppTheme.cardNextGradient
                : AppTheme.cardGradient,
        border: Border.all(
          color: isFocused
              ? AppTheme.focusBorder
              : isActive
                  ? AppTheme.goldPrimary
                  : isNext
                      ? AppTheme.goldAccent.withValues(alpha: 0.90)
                      : AppTheme.goldDim.withValues(alpha: 0.25),
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
              color: AppTheme.goldPrimary.withValues(alpha: 0.45),
              blurRadius: scale.scale(22, min: 16, max: 40),
              spreadRadius: 2,
            )
          else if (isActive)
            BoxShadow(
              color: AppTheme.goldPrimary.withValues(alpha: 0.35),
              blurRadius: scale.scale(24, min: 16, max: 44),
              spreadRadius: 2,
            )
          else if (isNext)
            BoxShadow(
              color: AppTheme.goldAccent.withValues(alpha: 0.24),
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
                        color: AppTheme.goldPrimary.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.85),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldPrimary.withValues(alpha: 0.20),
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
                            color: AppTheme.goldPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'الآن',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: scale.scale(12, min: 10, max: 20),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.goldPrimary,
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
                            color: AppTheme.goldAccent.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.goldAccent.withValues(alpha: 0.80),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.goldAccent.withValues(alpha: 0.16),
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
                                  color: AppTheme.goldLight,
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
                                  color: AppTheme.goldLight,
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          '✦',
                          style: TextStyle(
                            color: AppTheme.goldDim.withValues(alpha: 0.30),
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
                  ? AppTheme.goldPrimary
                  : isNext
                      ? AppTheme.goldLight
                      : AppTheme.textPrimary,
              shadows: [
                if (isActive)
                  Shadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.55),
                    blurRadius: scale.scale(12, min: 8, max: 20),
                  )
                else if (isNext)
                  Shadow(
                    color: AppTheme.goldLight.withValues(alpha: 0.40),
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

          // Delicate Islamic arched divider
          Container(
            margin: EdgeInsets.symmetric(vertical: scale.scale(5, min: 3, max: 10)),
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isActive
                      ? AppTheme.goldPrimary.withValues(alpha: 0.8)
                      : isNext
                          ? AppTheme.goldAccent.withValues(alpha: 0.6)
                          : AppTheme.goldDim.withValues(alpha: 0.22),
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
                  ? AppTheme.goldPrimary
                  : isNext
                      ? const Color(0xFFFFF59D) // Radiant champagne gold
                      : Colors.white,
              shadows: [
                if (isActive)
                  Shadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.65),
                    blurRadius: scale.scale(16, min: 10, max: 28),
                  )
                else if (isNext)
                  Shadow(
                    color: AppTheme.goldAccent.withValues(alpha: 0.50),
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
        ],
      ),
    );
  }
}
