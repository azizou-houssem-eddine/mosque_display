import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

export 'screen_scale.dart';

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

/// Visual theme palette model for watch face styling.
class ThemePalette {
  final String key;
  final String nameAr;
  final String descriptionAr;
  final Color bgDeep;
  final Color bgMid;
  final Color bgLight;
  final Color goldPrimary;
  final Color goldAccent;
  final Color goldDim;
  final Color goldLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final RadialGradient backgroundGradient;
  final LinearGradient cardGradient;
  final LinearGradient cardActiveGradient;
  final LinearGradient cardNextGradient;

  const ThemePalette({
    required this.key,
    required this.nameAr,
    required this.descriptionAr,
    required this.bgDeep,
    required this.bgMid,
    required this.bgLight,
    required this.goldPrimary,
    required this.goldAccent,
    required this.goldDim,
    required this.goldLight,
    this.textPrimary = const Color(0xFFF5F0E8),
    this.textSecondary = const Color(0xFFBEB9A8),
    required this.cardBg,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.cardActiveGradient,
    required this.cardNextGradient,
  });

  Color get backgroundTop => bgDeep;
  Color get primaryAccent => goldPrimary;
  Color get borderSoft => goldDim.withValues(alpha: 0.45);
  Color get borderGold => goldPrimary;
  Color get glowAccent => goldPrimary.withValues(alpha: 0.25);
  Color get cardBackground => cardBg;
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

  // --- Visual Watch Face Themes Catalog ---
  static const List<ThemePalette> availableThemes = [
    ThemePalette(
      key: 'royalEmerald',
      nameAr: 'الزمرد الملكي',
      descriptionAr: 'الأخضر المسجدي الجزائري العريق مع الذهب الملكي المضيء',
      bgDeep: Color(0xFF06231A),
      bgMid: Color(0xFF0B3326),
      bgLight: Color(0xFF0F4535),
      goldPrimary: Color(0xFFF2C94C),
      goldAccent: Color(0xFFD4AF37),
      goldDim: Color(0xFFB8962E),
      goldLight: Color(0xFFFFF176),
      cardBg: Color(0xFF0D3D28),
      backgroundGradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [Color(0xFF0B3326), Color(0xFF06231A)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0F4535), Color(0xFF08291C)],
      ),
      cardActiveGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E3C), Color(0xFF0D3B24)],
      ),
      cardNextGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF144D33), Color(0xFF0A2E1C)],
      ),
    ),
    ThemePalette(
      key: 'midnightSapphire',
      nameAr: 'الياقوت الأزرق',
      descriptionAr: 'كحلي الليل الملكي مع الذهب السماوي واللمسات الفضية',
      bgDeep: Color(0xFF040F1D),
      bgMid: Color(0xFF0A1F3B),
      bgLight: Color(0xFF132F52),
      goldPrimary: Color(0xFF5AC8FA),
      goldAccent: Color(0xFFD4AF37),
      goldDim: Color(0xFF2A6A9E),
      goldLight: Color(0xFF93C5FD),
      cardBg: Color(0xFF0E274A),
      backgroundGradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [Color(0xFF0A1F3B), Color(0xFF040F1D)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF132F52), Color(0xFF071B33)],
      ),
      cardActiveGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E4976), Color(0xFF0E2C4F)],
      ),
      cardNextGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF173B63), Color(0xFF0B233F)],
      ),
    ),
    ThemePalette(
      key: 'andalusianOnyx',
      nameAr: 'العقيق الأندلسي',
      descriptionAr: 'فحم رخامي عميق مع ذهب عنبري دافئ وعتيق',
      bgDeep: Color(0xFF0C0E12),
      bgMid: Color(0xFF151921),
      bgLight: Color(0xFF1E2430),
      goldPrimary: Color(0xFFFFAA00),
      goldAccent: Color(0xFFE59400),
      goldDim: Color(0xFFB87600),
      goldLight: Color(0xFFFFD166),
      cardBg: Color(0xFF181E29),
      backgroundGradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [Color(0xFF151921), Color(0xFF0C0E12)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1E2430), Color(0xFF11141A)],
      ),
      cardActiveGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2F3746), Color(0xFF1A1F29)],
      ),
      cardNextGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF262D3A), Color(0xFF141820)],
      ),
    ),
    ThemePalette(
      key: 'kiswahBlack',
      nameAr: 'الكسوة الشريفة',
      descriptionAr: 'أسود كعبة مطفأ OLED مع تطريز الذهب الخالص',
      bgDeep: Color(0xFF000000),
      bgMid: Color(0xFF0A0A0A),
      bgLight: Color(0xFF181818),
      goldPrimary: Color(0xFFE5C058),
      goldAccent: Color(0xFFC7A23E),
      goldDim: Color(0xFFA68429),
      goldLight: Color(0xFFF9E79F),
      cardBg: Color(0xFF111111),
      backgroundGradient: RadialGradient(
        center: Alignment.center,
        radius: 1.2,
        colors: [Color(0xFF0F0F0F), Color(0xFF000000)],
      ),
      cardGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF181818), Color(0xFF090909)],
      ),
      cardActiveGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2C2410), Color(0xFF161208)],
      ),
      cardNextGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF201B0C), Color(0xFF100E06)],
      ),
    ),
  ];

  static ThemePalette getThemePalette(String? key) {
    return availableThemes.firstWhere(
      (t) => t.key == key,
      orElse: () => availableThemes.first,
    );
  }

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

  static bool _fontsConfigured = false;

  /// Enforces offline font configuration and disables network downloading.
  static void ensureOfflineFonts() {
    if (!_fontsConfigured) {
      try {
        GoogleFonts.config.allowRuntimeFetching = false;
      } catch (_) {}
      _fontsConfigured = true;
    }
  }

  /// Builds a dynamic TextStyle using 100% offline bundled fonts for Du'as and Quranic texts.
  /// Resolves GoogleFonts network loader leaks by mapping to bundled assets (Amiri & Cairo).
  static TextStyle getIslamicStyle({
    String fontKey = 'amiriQuran',
    double fontSize = 28,
    Color color = goldPrimary,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.6,
    List<Shadow>? shadows,
  }) {
    ensureOfflineFonts();
    final String family = (fontKey == 'cairo') ? 'Cairo' : 'Amiri';
    return TextStyle(
      fontFamily: family,
      fontFamilyFallback: const ['Amiri', 'Cairo'],
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      height: height,
      shadows: shadows,
    );
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

