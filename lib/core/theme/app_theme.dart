import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Islamic font description model.
class IslamicFontOption {
  final String key;
  final String nameAr;
  final String descriptionAr;
  final String sample;

  const IslamicFontOption({
    required this.key,
    required this.nameAr,
    required this.descriptionAr,
    required this.sample,
  });
}

/// Concept 2 — Deep Royal Emerald + Radiant Gold
class AppTheme {
  // --- Palette ---
  static const Color emeraldDeep = Color(0xFF06231A);
  static const Color emeraldMid = Color(0xFF0B3326);
  static const Color emeraldLight = Color(0xFF0F4535);
  static const Color goldPrimary = Color(0xFFF2C94C);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldDim = Color(0xFFB8962E);
  static const Color goldLight = Color(0xFFFFF176);
  static const Color textPrimary = Color(0xFFF5F0E8);
  static const Color textSecondary = Color(0xFFBEB9A8);
  static const Color cardBg = Color(0xFF0D3D28);
  static const Color focusBorder = Color(0xFFF2C94C);

  // --- Islamic Fonts Catalog ---
  static const List<IslamicFontOption> islamicFonts = [
    IslamicFontOption(
      key: 'amiriQuran',
      nameAr: 'الخط القرآني (Amiri Quran)',
      descriptionAr:
          'خط المصحف الشريف ذو التشكيل البديع والمدّات والزخارف القرآنية الأصيلة',
      sample: '﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً﴾',
    ),
    IslamicFontOption(
      key: 'scheherazadeNew',
      nameAr: 'خط شهرزاد المطور (Scheherazade)',
      descriptionAr:
          'خط النسخ القرآني التقليدي التراثي برسم المصحف وجماليات النقط والحركات',
      sample: '﴿وَقُل رَّبِّ زِدْنِي عِلْمًا﴾ [طه: 114]',
    ),
    IslamicFontOption(
      key: 'amiri',
      nameAr: 'خط النسخ التراثي (Amiri)',
      descriptionAr:
          'خط المطبعة الأميرية الكلاسيكي المعتمد في كتب الحديث والأذكار',
      sample: '«اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ»',
    ),
    IslamicFontOption(
      key: 'arefRuqaa',
      nameAr: 'خط الرقعة العربي (Aref Ruqaa)',
      descriptionAr:
          'خط الرقعة الأصيل بجمالياته البصرية وانسيابيته اليدوية العريقة',
      sample: '«يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ»',
    ),
    IslamicFontOption(
      key: 'cairo',
      nameAr: 'الخط الحديث (Cairo)',
      descriptionAr:
          'خط هندسي واضح ومرتب مصمم لراحة العين وقراءة الشاشات البعيدة',
      sample: '﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾',
    ),
  ];

  /// Builds a dynamic TextStyle using Google Fonts for Du'as and Quranic texts.
  static TextStyle getIslamicStyle({
    String fontKey = 'amiriQuran',
    double fontSize = 28,
    Color color = goldPrimary,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.6,
    List<Shadow>? shadows,
  }) {
    switch (fontKey) {
      case 'amiriQuran':
        return GoogleFonts.amiriQuran(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        );
      case 'scheherazadeNew':
        return GoogleFonts.scheherazadeNew(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        );
      case 'arefRuqaa':
        return GoogleFonts.arefRuqaa(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        );
      case 'cairo':
        return GoogleFonts.cairo(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        );
      case 'amiri':
      default:
        return GoogleFonts.amiri(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: height,
          shadows: shadows,
        );
    }
  }

  // --- Gradients ---
  static const RadialGradient backgroundGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.2,
    colors: [emeraldMid, emeraldDeep],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4535), Color(0xFF08291C)],
  );

  static const LinearGradient cardActiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B5E3C), Color(0xFF0D3B24)],
  );

  static const LinearGradient cardNextGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF144D33), Color(0xFF0A2E1C)],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [goldPrimary, goldAccent],
  );

  static const LinearGradient metallicGoldGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFB8962E),
      Color(0xFFFFF176),
      Color(0xFFF2C94C),
      Color(0xFFD4AF37),
      Color(0xFFB8962E),
    ],
  );

  static List<BoxShadow> goldGlow({
    double blur = 20,
    double spread = 2,
    double alpha = 0.35,
  }) =>
      [
        BoxShadow(
          color: goldPrimary.withValues(alpha: alpha),
          blurRadius: blur,
          spreadRadius: spread,
        ),
        const BoxShadow(
          color: Colors.black54,
          blurRadius: 10,
          offset: Offset(0, 3),
        ),
      ];

  // --- ThemeData ---
  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: emeraldDeep,
        fontFamily: 'Cairo',
        colorScheme: const ColorScheme.dark(
          primary: goldPrimary,
          secondary: goldAccent,
          surface: emeraldMid,
          onPrimary: emeraldDeep,
          onSurface: textPrimary,
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: 2,
          ),
          displayMedium: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 64,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: goldPrimary,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 22,
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: goldPrimary,
          ),
        ),
        focusColor: goldPrimary.withValues(alpha: 0.3),
      );

  // --- Focus Decoration ---
  static BoxDecoration focusedDecoration({double borderRadius = 12}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: focusBorder, width: 3),
        boxShadow: [
          BoxShadow(
            color: goldPrimary.withValues(alpha: 0.4),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      );

  static BoxDecoration unfocusedDecoration({double borderRadius = 12}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: emeraldLight, width: 1),
      );
}

/// Traditional Islamic ornamental divider with gold gradient lines and rosette star.
class IslamicDivider extends StatelessWidget {
  final double maxWidth;
  final Color? color;
  final double height;
  final String centerSymbol;

  const IslamicDivider({
    super.key,
    this.maxWidth = 440,
    this.color,
    this.height = 24,
    this.centerSymbol = '۞',
  });

  @override
  Widget build(BuildContext context) {
    final gold = color ?? AppTheme.goldPrimary;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SizedBox(
          height: height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gold.withValues(alpha: 0.0),
                        gold.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(
                        color: gold.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      centerSymbol,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '✦',
                      style: TextStyle(
                        color: gold.withValues(alpha: 0.75),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  height: 1.2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gold.withValues(alpha: 0.7),
                        gold.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Responsive screen scaling helper for TV displays (720p HD Ready, 1080p Full HD, 4K Ultra HD).
/// Calibrated for distant 10-15m mosque viewing readability without clipping.
class ScreenScale {
  final double width;
  final double height;

  const ScreenScale({required this.width, required this.height});

  factory ScreenScale.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ScreenScale(width: size.width, height: size.height);
  }

  /// Compact TV display (720p HD Ready / dense viewports, height < 750)
  bool get isCompact => height < 750;

  /// Large TV display (4K Ultra HD / QHD, width >= 2560 or height >= 1440)
  bool get is4k => width >= 2560 || height >= 1440;

  /// Full HD display (1080p, standard TV baseline)
  bool get is1080p => !isCompact && !is4k;

  /// Continuous aspect-preserving scaling factor relative to 1920x1080 design canvas.
  /// Enforces a minimum legibility floor so distant prayer texts remain readable.
  double get factor {
    final scaleW = width / 1920.0;
    final scaleH = height / 1080.0;
    final base = scaleW < scaleH ? scaleW : scaleH;

    if (is4k) {
      return base.clamp(1.35, 2.2);
    } else if (isCompact) {
      // In compact or scaled TV viewports, maintain a comfortable legibility floor
      return base.clamp(0.84, 1.0);
    }
    return base.clamp(0.92, 1.15);
  }

  /// Proportionally scales a base dimension (defined for 1080p) with optional bounds.
  double scale(double base1080p, {double? min, double? max}) {
    final val = base1080p * factor;
    if (min != null && val < min) return min;
    if (max != null && val > max) return max;
    return val;
  }
}

