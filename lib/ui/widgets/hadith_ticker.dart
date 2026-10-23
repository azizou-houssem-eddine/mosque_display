import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import '../../core/theme/app_theme.dart';

/// Scrolling Hadith & Announcement ticker for the bottom of the mosque dashboard.
/// Supports multiple cycling messages joined by an ornamental Islamic separator.
class HadithTicker extends StatelessWidget {
  final List<String> items;
  final double fontSize;
  final double height;
  final String fontKey;

  /// Large collection of authentic Quranic supplications, prophetic prayers, and hadiths.
  static const List<String> defaultHadiths = [
    // Quranic Du'as
    'قال الله تعالى: ﴿رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ﴾ [البقرة: 201]',
    'قال الله تعالى: ﴿رَبِّ اجْعَلْنِي مُقِيمَ الصَّلَاةِ وَمِن ذُرِّيَّتِي رَبَّنَا وَتَقَبَّلْ دُعَاءِ﴾ [إبراهيم: 40]',
    'قال الله تعالى: ﴿رَبَّنَا لَا تُزِغْ قُلُوبَنَا بَعْدَ إِذْ هَدَيْتَنَا وَهَبْ لَنَا مِن لَّدُنكَ رَحْمَةً إِنَّكَ أَنتَ الْوَهَّابُ﴾ [آل عمران: 8]',
    'قال الله تعالى: ﴿رَبِّ اشْرَحْ لِي صَدْرِي ۝ وَيَسِّرْ لِي أَمْرِي﴾ [طه: 25-26]',
    'قال الله تعالى: ﴿لَّا إِلَهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ﴾ [الأنبياء: 87]',
    'قال الله تعالى: ﴿رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا﴾ [الإسراء: 24]',
    'قال الله تعالى: ﴿رَبَّنَا هَبْ لَنَا مِنْ أَزْوَاجِنَا وَذُرِّيَّاتِنَا قُرَّةَ أَعْيُنٍ وَاجْعَلْنَا لِلْمُتَّقِينَ إِمَامًا﴾ [الفرقان: 74]',
    'قال الله تعالى: ﴿رَبِّ أَوْزِعْنِي أَنْ أَشْكُرَ نِعْمَتَكَ الَّتِي أَنْعَمْتَ عَلَيَّ وَعَلَى وَالِدَيَّ﴾ [النمل: 19]',
    'قال الله تعالى: ﴿حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ﴾ [آل عمران: 173]',
    'قال الله تعالى: ﴿إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَوْقُوتًا﴾ [النساء: 103]',

    // Prophetic Du'as
    'دعاء نبوي: «اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ» (رواه أبو داود)',
    'دعاء نبوي: «يَا مُقَلِّبَ الْقُلُوبِ ثَبِّتْ قَلْبِي عَلَى دِينِكَ» (رواه الترمذي)',
    'دعاء نبوي: «اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي الدُّنْيَا وَالْآخِرَةِ» (رواه أبو داود)',
    'دعاء نبوي: «اللَّهُمَّ إِنِّي أَعُوذُ بِكَ مِنَ الْهَمِّ وَالْحَزَنِ، وَالْعَجْزِ وَالْكَسَلِ، وَالْبُخْلِ وَالْجُبْنِ» (صحيح البخاري)',
    'دعاء نبوي: «اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي» (رواه الترمذي)',
    'دعاء نبوي: «اللَّهُمَّ اهْدِنِي وَسَدِّدْنِي، وَأَصْلِحْ لِي شَأْنِي كُلَّهُ» (صحيح مسلم)',
    'سيد الاستغفار: «اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ خَلَقْتَنِي وَأَنَا عَبْدُكَ...» (صحيح البخاري)',

    // Mosque & Prayer Adhkar & Hadith
    'دعاء دخول المسجد: «اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ» (صحيح مسلم)',
    'دعاء بعد الأذان: «اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلَاةِ الْقَائِمَةِ آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ» (صحيح البخاري)',
    'بين الأذان والإقامة: «الدُّعَاءُ لَا يُرَدُّ بَيْنَ الْأَذَانِ وَالْإِقَامَةِ» (رواه الترمذي)',
    'قال رسول الله ﷺ: «مَن بَنَى لِلَّهِ مَسْجِدًا بَنَى اللَّهُ لَهُ مِثْلَهُ فِي الجَنَّةِ» (متفق عليه)',
    'قال رسول الله ﷺ: «صَلَاةُ الجَمَاعَةِ تَفْضُلُ صَلَاةَ الفَذِّ بِسَبْعٍ وَعِشْرِينَ دَرَجَةً» (متفق عليه)',
    'قال رسول الله ﷺ: «بَشِّرِ الْمَشَّائِينَ فِي الظُّلَمِ إِلَى الْمَسَاجِدِ بِالنُّورِ التَّامِّ يَوْمَ الْقِيَامَةِ» (رواه أبو داود)',
    'قال رسول الله ﷺ: «أَحَبُّ البِلَادِ إِلَى اللهِ مَسَاجِدُهَا» (رواه مسلم)',
    'قال رسول الله ﷺ: «مَنْ غَدَا إِلَى المَسْجِدِ أَوْ رَاحَ أَعَدَّ اللَّهُ لَهُ فِي الجَنَّةِ نُزُلًا كُلَّمَا غَدَا أَوْ رَاحَ» (متفق عليه)',
    'تذكير: يرجى التأكد من وضع الهواتف النقالة على الوضع الصامت داخل المسجد، بارك الله فيكم',
  ];

  static const String separator = '    ✦    ';

  HadithTicker({
    super.key,
    List<String>? items,
    String? text,
    this.fontSize = 26,
    this.height = 52,
    this.fontKey = 'amiriQuran',
  }) : items = items ??
            (text != null && text.trim().isNotEmpty
                ? [text.trim(), ...defaultHadiths]
                : defaultHadiths);

  @override
  Widget build(BuildContext context) {
    final combinedText = items.join(separator);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.85),
      ),
      child: Stack(
        children: [
          // Top metallic gold divider
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0x00D4AF37),
                    Color(0xFFF2C94C),
                    Color(0xFFFFF176),
                    Color(0xFFF2C94C),
                    Color(0x00D4AF37),
                  ],
                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // Central Marquee Content
          Positioned.fill(
            child: Marquee(
              text: combinedText,
              style: AppTheme.getIslamicStyle(
                fontKey: fontKey,
                fontSize: fontSize,
                color: AppTheme.goldPrimary,
                shadows: [
                  Shadow(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              scrollAxis: Axis.horizontal,
              crossAxisAlignment: CrossAxisAlignment.center,
              blankSpace: 120,
              velocity: 55,
              pauseAfterRound: const Duration(seconds: 1),
              startPadding: 32,
              accelerationDuration: const Duration(milliseconds: 500),
              accelerationCurve: Curves.easeIn,
              decelerationDuration: const Duration(milliseconds: 500),
              decelerationCurve: Curves.easeOut,
            ),
          ),

          // Left edge fade overlay
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 48,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.emeraldDeep,
                      AppTheme.emeraldDeep.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Right edge fade overlay
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 48,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      AppTheme.emeraldDeep,
                      AppTheme.emeraldDeep.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
