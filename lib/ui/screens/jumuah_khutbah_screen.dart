import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../widgets/mandala_background.dart';

/// Dedicated Friday (Jumu'ah) Khutbah Screen.
///
/// Suppresses normal ticking countdown and blackouts during the Imam's sermon.
/// Displays Friday reverence reminders, Hadith of silence (Insaat), virtues of Friday,
/// and appropriate Iqamah timing guidance.
class JumuahKhutbahScreen extends StatefulWidget {
  const JumuahKhutbahScreen({super.key});

  @override
  State<JumuahKhutbahScreen> createState() => _JumuahKhutbahScreenState();
}

class _JumuahKhutbahScreenState extends State<JumuahKhutbahScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final scale = ScreenScale.of(context,
        customScale: provider.settings.uiScaleFactor);
    final isSimulation = provider.isSimulationActive;

    // Approximate Iqamah time calculation
    String approximateIqamahText = 'تقام الصلاة فور فراغ الإمام من الخطبة';
    final schedule = provider.todaySchedule;
    if (schedule != null) {
      final dhuhrTime = schedule.dhuhr;
      final jumuahDelayMinutes =
          provider.settings.iqamahDelays.jumuah;
      final estTime = dhuhrTime.add(Duration(minutes: jumuahDelayMinutes));
      final h = estTime.hour.toString().padLeft(2, '0');
      final m = estTime.minute.toString().padLeft(2, '0');
      approximateIqamahText = 'موعد الإقامة التقريبي: $h:$m (بعد انتهاء الخطبة)';
    }

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
          } else if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA) {
            provider.enterBlackout();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Deep radial emerald background
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Color(0xFF0D3B24),
                    Color(0xFF06231A),
                    Colors.black,
                  ],
                  stops: [0.0, 0.7, 1.0],
                ),
              ),
            ),

            // Sacred Islamic mandala watermark
            const MandalaBackground(opacity: 0.08),

            // Main Content Area
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.scale(40, min: 20, max: 70),
                  vertical: scale.scale(20, min: 10, max: 36),
                ),
                child: Column(
                  children: [
                    // ── 1. Top Sacred Header (includes integrated action buttons) ──
                    _buildHeader(provider, scale, isSimulation),

                    SizedBox(height: scale.scale(16, min: 8, max: 26)),

                    // ── 2. Reverence & Khutbah Central Card ──
                    Expanded(
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: _buildCentralCard(provider, scale),
                        ),
                      ),
                    ),

                    SizedBox(height: scale.scale(16, min: 8, max: 26)),

                    // ── 3. Bottom Iqamah Timing & Sunan Guidance Strip ──
                    _buildBottomBar(approximateIqamahText, scale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
      DisplayProvider provider, ScreenScale scale, bool isSimulation) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scaleLayout(16, min: 10, max: 28),
        vertical: scale.scaleLayout(8, min: 4, max: 16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.75),
        borderRadius:
            BorderRadius.circular(scale.scaleLayout(16, min: 12, max: 24)),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Exit button (integrated into header)
          Flexible(
            fit: FlexFit.loose,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: Icon(
                  isSimulation ? Icons.close : Icons.arrow_back,
                  size: scale.scaleLayout(18, min: 14, max: 24),
                ),
                label: Text(
                  isSimulation
                      ? 'إنهاء المحاكاة (العودة للشاشة الرئيسية)'
                      : 'العودة للشاشة الرئيسية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scaleFont(15, min: 11, max: 20),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSimulation
                      ? Colors.redAccent.withValues(alpha: 0.25)
                      : AppTheme.emeraldMid.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: isSimulation
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
          ),
          SizedBox(width: scale.scaleLayout(8, min: 4, max: 14)),

          // Mosque Name
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.mosque,
                    color: AppTheme.goldPrimary,
                    size: scale.scaleLayout(22, min: 16, max: 32),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    provider.settings.mosqueName,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: scale.scaleFont(20, min: 14, max: 30),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: scale.scaleLayout(8, min: 4, max: 14)),

          // Central Title Badge
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.scaleLayout(18, min: 10, max: 28),
                  vertical: scale.scaleLayout(6, min: 3, max: 10),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.goldDim.withValues(alpha: 0.3),
                      AppTheme.goldPrimary.withValues(alpha: 0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                    width: 1,
                  ),
                ),
                child: Text(
                  '🕌 خُطْبَةُ يَوْمِ الجُمُعَةِ المُبَارَكَةِ',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scaleFont(22, min: 16, max: 32),
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          SizedBox(width: scale.scaleLayout(8, min: 4, max: 14)),

          // Hijri Date
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                provider.hijriDate,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: scale.scaleFont(18, min: 13, max: 26),
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: scale.scaleLayout(8, min: 4, max: 14)),

          // Start Prayer Early Button
          Flexible(
            fit: FlexFit.loose,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: Icon(
                  Icons.brightness_2,
                  color: AppTheme.goldPrimary,
                  size: scale.scaleLayout(18, min: 14, max: 24),
                ),
                label: Text(
                  'بدء الصلاة فوراً (Enter / OK)',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scaleFont(15, min: 11, max: 20),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldLight,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emeraldDeep.withValues(alpha: 0.9),
                  side: const BorderSide(
                    color: AppTheme.goldPrimary,
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => provider.enterBlackout(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCentralCard(DisplayProvider provider, ScreenScale scale) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: scale.is4k ? 1500 : (scale.isCompact ? 900 : 1200),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(36, min: 20, max: 60),
        vertical: scale.scale(24, min: 14, max: 40),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldMid.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(scale.scale(24, min: 16, max: 36)),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.6),
          width: scale.scale(1.8, min: 1.2, max: 2.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.15),
            blurRadius: scale.scale(30, min: 16, max: 50),
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reverence Notice Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✦',
                style: TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: scale.scale(20, min: 14, max: 28),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'أَنْصِتْ وَاسْتَمِعْ رَحِمَكَ اللهُ',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: scale.scale(26, min: 18, max: 38),
                  fontWeight: FontWeight.w700,
                  color: AppTheme.goldPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '✦',
                style: TextStyle(
                  color: AppTheme.goldAccent,
                  fontSize: scale.scale(20, min: 14, max: 28),
                ),
              ),
            ],
          ),

          SizedBox(height: scale.scale(14, min: 8, max: 22)),

          // Sacred Hadith on Insaat (Silent Reverence)
          Text(
            '«إِذَا قُلْتَ لِصَاحِبِكَ يَوْمَ الْجُمُعَةِ: أَنْصِتْ، وَالإِمَامُ يَخْطُبُ، فَقَدْ لَغَوْتَ»',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: scale.scale(36, min: 24, max: 54),
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.5,
              shadows: [
                Shadow(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.4),
                  blurRadius: scale.scale(14, min: 8, max: 24),
                ),
              ],
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: scale.scale(8, min: 4, max: 14)),

          Text(
            'متفق عليه عن أبي هريرة رضي الله عنه — صحيح البخاري ومسلم',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(16, min: 12, max: 24),
              color: AppTheme.goldDim,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
          ),

          // Divider
          Container(
            margin: EdgeInsets.symmetric(
              vertical: scale.scale(16, min: 10, max: 24),
            ),
            height: 1.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.goldPrimary.withValues(alpha: 0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Salawat upon the Prophet ﷺ
          Text(
            '«اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ وَعَلَى آلِهِ وَصَحْبِهِ أَجْمَعِينَ»',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: scale.scale(30, min: 20, max: 44),
              color: AppTheme.goldLight,
              fontWeight: FontWeight.w600,
            ),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: scale.scale(6, min: 4, max: 10)),

          Text(
            '«إِنَّ مِنْ أَفْضَلِ أَيَّامِكُمْ يَوْمَ الْجُمُعَةِ، فَأَكْثِرُوا عَلَيَّ مِنَ الصَّلَاةِ فِيهِ»',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(17, min: 12, max: 24),
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textDirection: TextDirection.rtl,
          ),

          SizedBox(height: scale.scale(16, min: 10, max: 24)),

          // 4 Virtues / Sunan badges
          Wrap(
            spacing: scale.scale(12, min: 8, max: 20),
            runSpacing: scale.scale(8, min: 4, max: 14),
            alignment: WrapAlignment.center,
            children: [
              _buildSunnahBadge('📖 سورة الكهف', 'نور ما بين الجمعتين', scale),
              _buildSunnahBadge('💧 الغسل والجمال', 'التطيب ولبس النظيف', scale),
              _buildSunnahBadge('🤲 ساعة الإجابة', 'تحري الدعاء المستجاب', scale),
              _buildSunnahBadge('🤫 حسن الإنصات', 'حضور القلب والأجر التام', scale),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSunnahBadge(String title, String subtitle, ScreenScale scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(14, min: 10, max: 22),
        vertical: scale.scale(8, min: 5, max: 12),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.goldDim.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(15, min: 11, max: 20),
              fontWeight: FontWeight.bold,
              color: AppTheme.goldPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: scale.scale(12, min: 9, max: 16),
              color: AppTheme.textSecondary,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(String approximateIqamahText, ScreenScale scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(24, min: 14, max: 36),
        vertical: scale.scale(10, min: 6, max: 16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(scale.scale(14, min: 10, max: 20)),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.access_time_filled,
              color: AppTheme.goldPrimary,
              size: scale.scale(20, min: 15, max: 28),
            ),
            const SizedBox(width: 10),
            Text(
              approximateIqamahText,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: scale.scale(18, min: 13, max: 26),
                fontWeight: FontWeight.bold,
                color: AppTheme.goldLight,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
