import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../domain/occasions/islamic_occasions_engine.dart';
import '../widgets/circular_gauge_widget.dart';
import '../widgets/mandala_background.dart';

/// Iqamah Countdown Screen — Fullscreen circular astrolabe gauge counting down to Iqamah.
/// Features royal Islamic header, date-specific / Adhan Du'a card, and congregation guidance.
class IqamahCountdownScreen extends StatefulWidget {
  const IqamahCountdownScreen({super.key});

  @override
  State<IqamahCountdownScreen> createState() => _IqamahCountdownScreenState();
}

class _IqamahCountdownScreenState extends State<IqamahCountdownScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final isAdhanAlert = provider.displayState == DisplayState.adhanAlert;
    final isIqamah = provider.displayState == DisplayState.iqamahCountdown;

    // Iqamah progress: 0.0 (start) → 1.0 (complete)
    Duration totalDelay = Duration.zero;
    if (isIqamah && provider.activePrayer != null) {
      totalDelay = Duration(
        minutes: provider.settings.iqamahDelays
            .getDelayFor(provider.activePrayer!),
      );
    }
    final remaining =
        isIqamah ? provider.iqamahRemaining : const Duration(seconds: 90);
    final total = isIqamah ? totalDelay : const Duration(seconds: 90);
    final progress = total.inSeconds > 0
        ? 1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 1.0;

    final prayerName = provider.activePrayer?.nameAr ?? '';

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack ||
              event.logicalKey == LogicalKeyboardKey.browserBack ||
              event.logicalKey == LogicalKeyboardKey.keyT ||
              event.logicalKey == LogicalKeyboardKey.keyS) {
            provider.dismissActiveState();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Deep radial emerald-gold background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Color(0xFF0A3326),
                    Color(0xFF041912),
                    Colors.black,
                  ],
                  stops: [0.0, 0.65, 1.0],
                ),
              ),
            ),

            // Sacred 16-point geometric mandala watermark
            const MandalaBackground(opacity: 0.07),

            // Exit / Back button (Top-Left)
            Positioned(
              top: 20,
              left: 20,
              child: ElevatedButton.icon(
                icon: Icon(
                  provider.isSimulationActive ? Icons.close : Icons.arrow_back,
                  size: 18,
                ),
                label: Text(
                  provider.isSimulationActive
                      ? 'إنهاء المحاكاة (Esc / T)'
                      : 'العودة للشاشة الرئيسية',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isSimulationActive
                      ? Colors.redAccent.withValues(alpha: 0.25)
                      : AppTheme.emeraldMid.withValues(alpha: 0.75),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: provider.isSimulationActive
                        ? Colors.redAccent
                        : AppTheme.goldDim.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => provider.dismissActiveState(),
              ),
            ),

            // Main Content Layout with Responsive Scaling for 720p, 1080p, 4K
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = ScreenScale.of(context);
                  final h = constraints.maxHeight;
                  final isCompact = scale.isCompact;
                  final gaugeSize = scale.is4k
                      ? (h * 0.42).clamp(420.0, 850.0)
                      : isCompact
                          ? (h * 0.38).clamp(210.0, 290.0)
                          : (h * 0.42).clamp(320.0, 480.0);
                  final titleSize = scale.scale(54.0, min: 36.0, max: 96.0);
                  final duaFontSize = scale.scale(26.0, min: 19.0, max: 48.0);
                  final verticalPadding = scale.scale(16.0, min: 8.0, max: 32.0);

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale.scale(28, min: 16, max: 56),
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      children: [
                        // ── 1. Top Sacred Header ─────────────────────────────
                        _buildTopHeader(isAdhanAlert, prayerName,
                            titleSize: titleSize),

                        const Spacer(flex: 1),

                        // ── 2. Centre Section: Gauge & Countdown ─────────────
                        if (isAdhanAlert)
                          _AdhanPulseWidget(
                            prayerName: prayerName,
                            size: gaugeSize * 0.9,
                          )
                        else
                          CircularGaugeWidget(
                            progress: progress,
                            centerLabel:
                                DisplayProvider.formatMinSec(remaining),
                            subtitle: 'حَتَّى الإِقَامَةِ',
                            size: gaugeSize,
                            segments: 60,
                          ),

                        const Spacer(flex: 1),

                        // ── 3. Date-Specific / Adhan Du'a Box ─────────────────
                        _buildSupplicationBox(
                          provider,
                          fontSize: duaFontSize,
                          isCompact: isCompact,
                          scale: scale,
                        ),

                        SizedBox(height: scale.scale(16, min: 8, max: 28)),

                        // ── 4. Bottom Mosque Etiquette & Guidance Bar ────────
                        _buildBottomGuidanceBar(
                          isCompact: isCompact,
                          scale: scale,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Header displaying Bismillah, Prayer title, and illuminated status badge.
  Widget _buildTopHeader(bool isAdhanAlert, String prayerName,
      {double titleSize = 54}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bismillah Calligraphy
        Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: titleSize > 44 ? 22 : 18,
            color: AppTheme.goldDim.withValues(alpha: 0.85),
            letterSpacing: 2,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 4),

        // Main Title
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star,
                color: AppTheme.goldPrimary, size: titleSize > 44 ? 22 : 18),
            const SizedBox(width: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                isAdhanAlert
                    ? 'حَانَ الآنَ مَوْعِدُ أَذَانِ $prayerName'
                    : 'إِقَامَةُ صَلَاةِ $prayerName',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldPrimary,
                  shadows: const [
                    Shadow(
                      color: AppTheme.goldPrimary,
                      blurRadius: 20,
                    ),
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.star,
                color: AppTheme.goldPrimary, size: titleSize > 44 ? 22 : 18),
          ],
        ),
      ],
    );
  }

  /// Sacred Du'a Box: Displays authentic occasion Du'a or Adhan/Iqamah Du'a.
  Widget _buildSupplicationBox(
    DisplayProvider provider, {
    double fontSize = 26,
    bool isCompact = false,
    required ScreenScale scale,
  }) {
    final occasion = provider.primaryOccasion;

    // Pick contextual Du'a & title
    String badgeTitle = '✦ الدُّعَاءُ بَيْنَ الأَذَانِ وَالإِقَامَةِ مُسْتَجَابٌ ✦';
    String mainDua =
        '«اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ، وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ»';
    String attribution =
        'قال رسول الله ﷺ: «الدُّعَاءُ لَا يُرَدُّ بَيْنَ الْأَذَانِ وَالْإِقَامَةِ» (رواه الترمذي)';

    if (occasion != null) {
      switch (occasion.type) {
        case OccasionType.friday:
          badgeTitle = '✦ دُعَاءُ يَوْمِ الجُمُعَةِ المُبَارَكَةِ — سَاعَةُ الإِجَابَةِ ✦';
          mainDua = occasion.primaryDuaAr ??
              '«اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ، اللَّهُمَّ اغْفِرْ لَنَا ذُنُوبَنَا وَفَرِّجْ كُرُوبَنَا وَتَقَبَّلْ دُعَاءَنَا»';
          attribution = occasion.hadithAr ??
              'قال رسول الله ﷺ: «إِنَّ فِي الْجُمُعَةِ لَسَاعَةً لَا يُوَافِقُهَا عَبْدٌ مُسْلِمٌ يَسْأَلُ اللَّهَ شَيْئًا إِلَّا أَعْطَاهُ إِيَّاهُ»';
          break;

        case OccasionType.ramadan:
          badgeTitle = '✦ دُعَاءُ شَهْرِ رَمَضَانَ المُبَارَكِ ✦';
          mainDua = occasion.primaryDuaAr ??
              '«اللَّهُمَّ إِنَّكَ عَفُوٌّ كَرِيمٌ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي، اللَّهُمَّ تَقَبَّلْ صِيَامَنَا وَقِيَامَنَا»';
          attribution = occasion.hadithAr ??
              '«مَنْ صَامَ رَمَضَانَ إِيمَانًا وَاحْتِسَابًا غُفِرَ لَهُ مَا تَقَدَّمَ مِنْ ذَنْبِهِ»';
          break;

        case OccasionType.eidFitr:
        case OccasionType.eidAdha:
          badgeTitle = '✦ تَكْبِيرَاتُ وَأَدْعِيَةُ العِيدِ المُبَارَكِ ✦';
          mainDua =
              '«اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، لَا إِلَهَ إِلَّا اللهُ، اللهُ أَكْبَرُ، اللهُ أَكْبَرُ، وَلِلَّهِ الْحَمْدُ»';
          attribution = occasion.hadithAr ??
              '«تَقَبَّلَ اللهُ مِنَّا وَمِنْكُمُ الصِّيَامَ وَالْقِيَامَ وَصَالِحَ الْأَعْمَالِ»';
          break;

        case OccasionType.arafah:
          badgeTitle = '✦ خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ ✦';
          mainDua =
              '«لَا إِلَهَ إِلَّا اللهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ»';
          attribution =
              'قال رسول الله ﷺ: «خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ» (رواه الترمذي)';
          break;

        case OccasionType.ashura:
          badgeTitle = '✦ دُعَاءُ وَفَضَائِلُ يَوْمِ عَاشُورَاءَ ✦';
          mainDua = occasion.primaryDuaAr ??
              '«اللَّهُمَّ يَا فَاَرِجَ الْهَمِّ، وَيَا كَاشِفَ الْغَمِّ، نَجِّنَا وَاغْفِرْ لَنَا مَغْفِرَةً تُطَهِّرُ بِهَا قُلُوبَنَا»';
          attribution = occasion.hadithAr ??
              '«صِيَامُ يَوْمِ عَاشُورَاءَ أَحْتَسِبُ عَلَى اللهِ أَنْ يُكَفِّرَ السَّنَةَ الَّتِي قَبْلَهُ»';
          break;

        case OccasionType.mawlid:
          badgeTitle = '✦ الصَّلَاةُ عَلَى النَّبِيِّ ﷺ فِي ذِكْرَى المَوْلِدِ الشَّرِيفِ ✦';
          mainDua = occasion.primaryDuaAr ??
              '«اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا وَحَبِيبِنَا مُحَمَّدٍ رَسُولِ اللهِ ﷺ»';
          attribution =
              'قال رسول الله ﷺ: «مَنْ صَلَّى عَلَيَّ صَلَاةً صَلَّى اللَّهُ عَلَيْهِ بِهَا عَشْرًا»';
          break;

        case OccasionType.islamicNewYear:
          badgeTitle = '✦ دُعَاءُ رَأْسِ السَّنَةِ الهِجْرِيَّةِ الجَدِيدَةِ ✦';
          mainDua = occasion.primaryDuaAr ??
              '«اللَّهُمَّ أَدْخِلْهُ عَلَيْنَا بِالْأَمْنِ وَالْإِيمَانِ، وَالسَّلَامَةِ وَالْإِسْلَامِ»';
          attribution = '«اللَّهُمَّ اجْعَلْهُ عَامَ خَيْرٍ وَبَرَكَةٍ وَنَصْرٍ لِلْمُسْلِمِينَ»';
          break;
      }
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: scale.is4k ? 1800 : (isCompact ? 840 : 1000),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(24, min: 16, max: 48),
        vertical: scale.scale(isCompact ? 10 : 14, min: 8, max: 24),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF06231A).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(scale.scale(18, min: 14, max: 32)),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.65),
          width: scale.scale(1.4, min: 1.0, max: 2.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.18),
            blurRadius: scale.scale(20, min: 12, max: 36),
            spreadRadius: 2,
          ),
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge Pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: scale.scale(16, min: 12, max: 32),
              vertical: scale.scale(3, min: 2, max: 6),
            ),
            decoration: BoxDecoration(
              color: AppTheme.goldPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.goldPrimary.withValues(alpha: 0.7),
                width: 1,
              ),
            ),
            child: Text(
              badgeTitle,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: scale.scale(isCompact ? 13 : 15, min: 11, max: 26),
                fontWeight: FontWeight.bold,
                color: AppTheme.goldPrimary,
              ),
              textDirection: TextDirection.rtl,
            ),
          ),
          SizedBox(height: scale.scale(isCompact ? 6 : 8, min: 4, max: 14)),

          // Vocalized Du'a Text
          Text(
            mainDua,
            style: AppTheme.getIslamicStyle(
              fontKey: provider.settings.islamicFont,
              fontSize: fontSize,
              color: const Color(0xFFFFF9E6),
            ).copyWith(height: 1.55),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),

          // Subtle ornamental divider between Du'a and attribution
          Container(
            margin: EdgeInsets.symmetric(
              vertical: scale.scale(6, min: 3, max: 12),
            ),
            height: 1.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.goldDim.withValues(alpha: 0.35),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Attribution / Hadith
          Text(
            attribution,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(isCompact ? 12 : 14, min: 10, max: 24),
              color: AppTheme.goldAccent,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  /// Bottom Mosque Etiquette bar: Phone silence & Straighten rows reminder.
  Widget _buildBottomGuidanceBar({
    bool isCompact = false,
    required ScreenScale scale,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: scale.is4k ? 2000 : (isCompact ? 880 : 1100),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(20, min: 14, max: 40),
        vertical: scale.scale(isCompact ? 6 : 8, min: 4, max: 16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(scale.scale(14, min: 10, max: 24)),
        border: Border.all(
          color: AppTheme.goldDim.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.phone_android,
                  color: Colors.amberAccent,
                  size: scale.scale(isCompact ? 18 : 20, min: 14, max: 36),
                ),
                SizedBox(width: scale.scale(8, min: 5, max: 14)),
                Text(
                  'يُرْجَى وَضْعُ الهَوَاتِفِ عَلَى الوَضْعِ الصَّامِتِ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scale(isCompact ? 14 : 16, min: 12, max: 28),
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(16, min: 10, max: 32),
              ),
              child: Text(
                '✦',
                style: TextStyle(
                  color: AppTheme.goldPrimary,
                  fontSize: scale.scale(18, min: 13, max: 32),
                ),
              ),
            ),
            Text(
              '«اسْتَوُوا وَاعْتَدِلُوا وَسَوُّوا صُفُوفَكُمْ»',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: scale.scale(isCompact ? 18 : 20, min: 14, max: 36),
                color: AppTheme.goldLight,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pulsing Adhan alert animation (before Iqamah countdown).
class _AdhanPulseWidget extends StatefulWidget {
  final String prayerName;
  final double size;

  const _AdhanPulseWidget({
    required this.prayerName,
    this.size = 320,
  });

  @override
  State<_AdhanPulseWidget> createState() => _AdhanPulseWidgetState();
}

class _AdhanPulseWidgetState extends State<_AdhanPulseWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textSize = (widget.size * 0.16).clamp(32.0, 52.0);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFF0F3E2E), Color(0xFF03160F)],
          ),
          border: Border.all(color: AppTheme.goldPrimary, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.goldPrimary.withValues(alpha: 0.55),
              blurRadius: 50,
              spreadRadius: 12,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اللهُ أَكْبَرُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldPrimary,
                  height: 1.2,
                ),
                textDirection: TextDirection.rtl,
              ),
              Text(
                'اللهُ أَكْبَرُ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.goldPrimary,
                  height: 1.2,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

