import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/app_theme.dart';
import '../../core/providers/display_provider.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/wilaya.dart';
import '../../domain/occasions/islamic_occasions_engine.dart';
import '../widgets/circular_gauge_widget.dart';
import '../widgets/prayer_card_widget.dart';
import '../widgets/mandala_background.dart';
import '../widgets/hadith_ticker.dart';
import 'iqamah_countdown_screen.dart';
import 'salat_blackout_screen.dart';
import 'adhkar_carousel_screen.dart';
import 'settings_screen.dart';
import 'dua_showcase_screen.dart';
import '../widgets/simulation_control_dialog.dart';

/// Main TV dashboard — Standard Mode.
/// Clock, Hijri date, symmetric prayer cards, central circular gauge, ticker.
class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late Timer _ticker;
  DateTime _now = DateTime.now();
  final FocusNode _screenFocusNode = FocusNode();
  final FocusNode _settingsButtonFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
      context.read<DisplayProvider>().tick();
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _screenFocusNode.dispose();
    _settingsButtonFocusNode.dispose();
    super.dispose();
  }

  String get _timeStr {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final schedule = provider.todaySchedule;
    final occasions = IslamicOccasionsEngine.getOccasions(
      provider.effectiveDate,
      hijriOffsetDays: provider.settings.hijriOffsetDays,
    );

    // State routing
    switch (provider.displayState) {
      case DisplayState.adhanAlert:
      case DisplayState.iqamahCountdown:
        return const IqamahCountdownScreen();
      case DisplayState.salatBlackout:
        return const SalatBlackoutScreen();
      case DisplayState.postSalatAdhkar:
        return const AdhkarCarouselScreen();
      case DisplayState.standard:
        break;
    }

    return KeyboardListener(
      focusNode: _screenFocusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.numpadEnter ||
              event.logicalKey == LogicalKeyboardKey.gameButtonA ||
              event.logicalKey == LogicalKeyboardKey.f1 ||
              event.logicalKey == LogicalKeyboardKey.keyM ||
              event.logicalKey == LogicalKeyboardKey.contextMenu) {
            _openSettings(context);
          }
          if (event.logicalKey == LogicalKeyboardKey.keyD) {
            _openDuaShowcase(context);
          }
          if (event.logicalKey == LogicalKeyboardKey.keyT ||
              event.logicalKey == LogicalKeyboardKey.keyS ||
              event.logicalKey == LogicalKeyboardKey.f3) {
            _openSimulationDialog(context);
          }
          if (event.logicalKey == LogicalKeyboardKey.mediaFastForward ||
              event.logicalKey == LogicalKeyboardKey.f2 ||
              event.logicalKey == LogicalKeyboardKey.digit5) {
            // D-pad shortcut — trigger Adhkar on demand
            provider.triggerAdhkarOnDemand();
          }
          if (event.logicalKey == LogicalKeyboardKey.digit1) {
            provider.resetSimulation();
          }
          if (event.logicalKey == LogicalKeyboardKey.digit2) {
            provider.simulateDisplayState(DisplayState.adhanAlert);
          }
          if (event.logicalKey == LogicalKeyboardKey.digit3) {
            provider.simulateDisplayState(
              DisplayState.iqamahCountdown,
              customDuration: const Duration(seconds: 30),
            );
          }
          if (event.logicalKey == LogicalKeyboardKey.digit4) {
            provider.simulateDisplayState(
              DisplayState.salatBlackout,
              customDuration: const Duration(seconds: 20),
            );
          }
          if (event.logicalKey == LogicalKeyboardKey.digit6) {
            provider.simulateOccasion(OccasionType.friday);
          }
          if (event.logicalKey == LogicalKeyboardKey.digit7) {
            provider.simulateOccasion(OccasionType.ramadan);
          }
          if (event.logicalKey == LogicalKeyboardKey.digit8) {
            provider.simulateOccasion(OccasionType.eidFitr);
          }
          if (event.logicalKey == LogicalKeyboardKey.digit9) {
            provider.simulateOccasion(OccasionType.arafah);
          }
        }
      },
      child: GestureDetector(
        onLongPress: () => _openSettings(context),
        child: Scaffold(
          backgroundColor: AppTheme.emeraldDeep,
          body: Stack(
            children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
              ),
              // Mandala watermark
              const MandalaBackground(opacity: 0.07),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(provider, schedule, occasions),
                    if (occasions.isNotEmpty)
                      _buildOccasionBanner(occasions.first),
                    Expanded(
                      child: _buildBody(provider, schedule),
                    ),
                    _buildTicker(provider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    DisplayProvider provider,
    PrayerSchedule? schedule,
    List<IslamicOccasion> occasions,
  ) {
    final scale = ScreenScale.of(context);
    final currentWilaya = algerianWilayas.firstWhere(
      (w) => w.code == provider.settings.selectedWilayaCode,
      orElse: () => algerianWilayas.first,
    );
    final occasionBanner =
        occasions.isNotEmpty ? occasions.first.titleAr : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(28, min: 16, max: 56),
        vertical: scale.scale(10, min: 6, max: 18),
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0x66D4AF37),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Mosque name & Wilaya/Commune (Clickable / Focusable for Settings)
          Flexible(
            flex: 3,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Focus(
                  focusNode: _settingsButtonFocusNode,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.select ||
                         event.logicalKey == LogicalKeyboardKey.enter ||
                         event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
                      _openSettings(context);
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(builder: (ctx) {
                    final isFocused = Focus.of(ctx).hasFocus;
                    return GestureDetector(
                      onTap: () => _openSettings(context),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.symmetric(
                            horizontal: scale.scale(isFocused ? 12 : 6, min: 4, max: 16),
                            vertical: scale.scale(isFocused ? 6 : 2, min: 2, max: 8),
                          ),
                          decoration: isFocused
                              ? BoxDecoration(
                                  color: AppTheme.emeraldMid.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(scale.scale(14, min: 8, max: 20)),
                                  border: Border.all(color: AppTheme.focusBorder, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.7),
                                      blurRadius: 14,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: EdgeInsets.all(scale.scale(7, min: 5, max: 14)),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldMid,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.goldDim.withValues(alpha: 0.6),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.mosque,
                                  color: AppTheme.goldPrimary,
                                  size: scale.scale(20, min: 16, max: 36),
                                ),
                              ),
                              SizedBox(width: scale.scale(10, min: 6, max: 18)),
                              Text(
                                provider.settings.mosqueName,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: scale.scale(32, min: 22, max: 56),
                                  color: AppTheme.goldPrimary,
                                  fontWeight: FontWeight.w700,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                              SizedBox(width: scale.scale(12, min: 8, max: 20)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: scale.scale(12, min: 8, max: 22),
                                  vertical: scale.scale(4, min: 2, max: 8),
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.emeraldMid.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(scale.scale(10, min: 8, max: 18)),
                                  border: Border.all(
                                    color: AppTheme.goldDim.withValues(alpha: 0.55),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.goldPrimary.withValues(alpha: 0.12),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  provider.activeCommune != null
                                      ? 'ولاية ${currentWilaya.nameAr} - ${provider.activeCommune!.nameAr}'
                                      : 'ولاية ${currentWilaya.nameAr} (${currentWilaya.code.toString().padLeft(2, '0')})',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: scale.scale(16, min: 12, max: 28),
                                    color: AppTheme.goldPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              if (provider.isSimulationActive) ...[
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () => _openSimulationDialog(context),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.goldPrimary, width: 1),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bolt,
                                            color: AppTheme.goldPrimary, size: 16),
                                        SizedBox(width: 4),
                                        Text(
                                          'محاكاة نشطة (T)',
                                          style: TextStyle(
                                            fontFamily: 'Cairo',
                                            fontSize: 13,
                                            color: AppTheme.goldPrimary,
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
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // High-Contrast TV Digital Clock (Visible from 15m)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.scale(22, min: 14, max: 44),
                  vertical: scale.scale(4, min: 2, max: 10),
                ),
                decoration: BoxDecoration(
                  color: AppTheme.emeraldDeep.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
                  border: Border.all(
                    color: AppTheme.goldDim.withValues(alpha: 0.45),
                    width: scale.scale(1.4, min: 1.0, max: 2.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldPrimary.withValues(alpha: 0.20),
                      blurRadius: scale.scale(20, min: 12, max: 40),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Text(
                  _timeStr,
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: scale.scale(58, min: 38, max: 108),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: scale.scale(3.5, min: 2.0, max: 6.5),
                    shadows: [
                      Shadow(
                        color: AppTheme.goldPrimary,
                        blurRadius: scale.scale(18, min: 12, max: 36),
                      ),
                      const Shadow(
                        color: Colors.black87,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Hijri Date, Occasion, & Action Buttons
          Flexible(
            flex: 3,
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: AppTheme.goldDim,
                        size: scale.scale(26, min: 20, max: 44),
                      ),
                      tooltip: 'محاكاة الحالات والمناسبات (T / S)',
                      onPressed: () => _openSimulationDialog(context),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: Icon(
                        Icons.auto_stories,
                        color: AppTheme.goldDim,
                        size: scale.scale(26, min: 20, max: 44),
                      ),
                      tooltip: 'معرض الأدعية والخطوط الإسلامية (D)',
                      onPressed: () => _openDuaShowcase(context),
                    ),
                    SizedBox(width: scale.scale(12, min: 8, max: 20)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          provider.hijriDate,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: scale.scale(25, min: 16, max: 46),
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            shadows: const [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        if (occasionBanner != null)
                          Text(
                            occasionBanner,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: scale.scale(17, min: 12, max: 30),
                              color: AppTheme.goldPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(DisplayProvider provider, PrayerSchedule? schedule) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.goldPrimary),
      );
    }
    if (provider.error != null || schedule == null) {
      return const Center(
        child: Text(
          'تعذّر تحميل مواقيت الصلاة',
          style: TextStyle(
              fontSize: 32, color: AppTheme.goldPrimary, fontFamily: 'Cairo'),
          textDirection: TextDirection.rtl,
        ),
      );
    }

    final countdown = provider.countdownToNextAdhan;
    const totalDay = Duration(hours: 24);
    final progress =
        1.0 - (countdown.inSeconds / totalDay.inSeconds).clamp(0.0, 1.0);
    final nextPrayer = schedule.getNextPrayer(_now);
    final currentPrayer = schedule.getCurrentPrayer(_now);

    // Left cards: Fajr, Shuruk, Dhuhr
    final leftPrayers = [Prayer.fajr, Prayer.sunrise, Prayer.dhuhr];
    // Right cards: Asr, Maghrib, Isha
    final rightPrayers = [Prayer.asr, Prayer.maghrib, Prayer.isha];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ScreenScale.of(context);
        final colWidth = (constraints.maxWidth * 0.28).clamp(180.0, scale.is4k ? 700.0 : 420.0);
        final cardWidth = (colWidth * 0.88).clamp(170.0, scale.is4k ? 580.0 : 340.0);
        final maxCenterWidth = constraints.maxWidth - (colWidth * 2);
        final maxSide = (maxCenterWidth < constraints.maxHeight ? maxCenterWidth : constraints.maxHeight);
        final gaugeSize = (maxSide * 0.82).clamp(240.0, scale.is4k ? 1000.0 : 520.0);

        return Row(
          children: [
            // Left prayer cards
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scale.scale(16, min: 10, max: 32)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: leftPrayers.map((p) {
                    final t = schedule.getTime(p);
                    final timeStr =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    return PrayerCardWidget(
                      prayerNameAr: p.nameAr,
                      time: timeStr,
                      isActive: currentPrayer == p,
                      isNext: nextPrayer == p,
                      width: cardWidth,
                    );
                  }).toList(),
                ),
              ),
            ),
            // Central Astrolabe Gauge
            Expanded(
              flex: 3,
              child: Center(
                child: CircularGaugeWidget(
                  progress: progress,
                  centerLabel: DisplayProvider.formatDuration(countdown),
                  subtitle: 'حتى ${nextPrayer.nameAr}',
                  size: gaugeSize,
                ),
              ),
            ),
            // Right prayer cards
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scale.scale(16, min: 10, max: 32)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: rightPrayers.map((p) {
                    final t = schedule.getTime(p);
                    final timeStr =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    return PrayerCardWidget(
                      prayerNameAr: p.nameAr,
                      time: timeStr,
                      isActive: currentPrayer == p,
                      isNext: nextPrayer == p,
                      width: cardWidth,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicker(DisplayProvider provider) {
    final scale = ScreenScale.of(context);
    final custom = provider.settings.marqueeText.trim();
    final customLines = custom.isNotEmpty
        ? custom
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList()
        : <String>[];
    return HadithTicker(
      items: [
        ...customLines,
        ...provider.occasionDuas,
        ...HadithTicker.defaultHadiths,
      ],
      fontKey: provider.settings.islamicFont,
      height: scale.scale(52, min: 42, max: 92),
      fontSize: scale.scale(26, min: 19, max: 46),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  void _openDuaShowcase(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DuaShowcaseScreen()),
    );
  }

  void _openSimulationDialog(BuildContext context) {
    SimulationControlDialog.show(context);
  }

  Widget _buildOccasionBanner(IslamicOccasion occ) {
    final scale = ScreenScale.of(context);
    final displayText = occ.primaryDuaAr != null
        ? '✦ ${occ.titleAr} ✦   ${occ.primaryDuaAr!}'
        : '✦ ${occ.titleAr} ✦   ${occ.messageAr ?? ""}';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: scale.scale(48, min: 20, max: 96),
        vertical: scale.scale(6, min: 3, max: 12),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(24, min: 12, max: 48),
        vertical: scale.scale(8, min: 4, max: 16),
      ),
      decoration: BoxDecoration(
        color: AppTheme.emeraldDeep.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
        border: Border.all(
          color: AppTheme.goldPrimary,
          width: scale.scale(1.5, min: 1.0, max: 2.8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.25),
            blurRadius: scale.scale(16, min: 10, max: 32),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star,
              color: AppTheme.goldPrimary,
              size: scale.scale(20, min: 14, max: 36)),
          SizedBox(width: scale.scale(12, min: 8, max: 20)),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: scale.scale(22, min: 15, max: 40),
                color: AppTheme.goldPrimary,
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: scale.scale(12, min: 8, max: 20)),
          Icon(Icons.star,
              color: AppTheme.goldPrimary,
              size: scale.scale(20, min: 14, max: 36)),
        ],
      ),
    );
  }
}
