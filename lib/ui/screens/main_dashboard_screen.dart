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
import 'jumuah_khutbah_screen.dart';
import 'settings_screen.dart';
import 'dua_showcase_screen.dart';
import '../widgets/simulation_control_dialog.dart';
import '../widgets/qr_pairing_dialog.dart';

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
  DateTime? _lastBackPressTime;
  DisplayState? _lastObservedState;

  void _onDisplayStateCheck() {
    if (!mounted) return;
    final currentState = context.read<DisplayProvider>().displayState;
    if (_lastObservedState != currentState) {
      _lastObservedState = currentState;
      if (currentState == DisplayState.salatBlackout ||
          currentState == DisplayState.adhanAlert ||
          currentState == DisplayState.iqamahCountdown ||
          currentState == DisplayState.jumuahKhutbah) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  void _handleBackPress() {
    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'اضغط مرة أخرى للخروج',
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
            textDirection: TextDirection.rtl,
          ),
          duration: Duration(seconds: 2),
          backgroundColor: AppTheme.emeraldMid,
        ),
      );
    } else {
      SystemNavigator.pop();
    }
  }

  DisplayProvider? _displayProvider;

  @override
  void initState() {
    super.initState();
    final provider = context.read<DisplayProvider>();
    _displayProvider = provider;
    _now = provider.effectiveDate;
    _lastObservedState = provider.displayState;
    provider.addListener(_onDisplayStateCheck);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      context.read<DisplayProvider>().tick();
      setState(() => _now = context.read<DisplayProvider>().effectiveDate);
    });
  }

  @override
  void dispose() {
    _displayProvider?.removeListener(_onDisplayStateCheck);
    _ticker.cancel();
    _screenFocusNode.dispose();
    _settingsButtonFocusNode.dispose();
    super.dispose();
  }

  String get _timeStr {
    final showSeconds = context.read<DisplayProvider>().settings.showSeconds;
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    if (!showSeconds) return '$h:$m';
    final s = _now.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DisplayProvider>();
    final schedule = provider.todaySchedule;
    final occasions = provider.activeOccasions;

    // State routing wrapped in PopScope so Android TV Back button returns to standard mode
    // instead of exiting the application.
    switch (provider.displayState) {
      case DisplayState.adhanAlert:
      case DisplayState.iqamahCountdown:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) provider.dismissActiveState();
          },
          child: const IqamahCountdownScreen(),
        );
      case DisplayState.jumuahKhutbah:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) provider.dismissActiveState();
          },
          child: const JumuahKhutbahScreen(),
        );
      case DisplayState.salatBlackout:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) provider.dismissActiveState();
          },
          child: const SalatBlackoutScreen(),
        );
      case DisplayState.postSalatAdhkar:
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) provider.dismissAdhkar();
          },
          child: const AdhkarCarouselScreen(),
        );
      case DisplayState.standard:
        break;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Focus(
        focusNode: _screenFocusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.escape ||
                event.logicalKey == LogicalKeyboardKey.goBack) {
              _handleBackPress();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.f1 ||
              event.logicalKey == LogicalKeyboardKey.keyM ||
              event.logicalKey == LogicalKeyboardKey.contextMenu) {
            _openSettings(context);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyD) {
            _openDuaShowcase(context);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyQ) {
            _openQrPairing(context);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyT ||
              event.logicalKey == LogicalKeyboardKey.keyS ||
              event.logicalKey == LogicalKeyboardKey.f3) {
            _openSimulationDialog(context);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.mediaFastForward ||
              event.logicalKey == LogicalKeyboardKey.f2 ||
              event.logicalKey == LogicalKeyboardKey.digit5) {
            provider.triggerAdhkarOnDemand();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit1) {
            provider.resetSimulation();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit2) {
            provider.simulateDisplayState(DisplayState.adhanAlert);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit3) {
            provider.simulateDisplayState(
              DisplayState.iqamahCountdown,
              customDuration: const Duration(seconds: 30),
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit4) {
            provider.simulateDisplayState(
              DisplayState.salatBlackout,
              customDuration: const Duration(seconds: 20),
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit6) {
            provider.simulateOccasion(OccasionType.friday);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit7) {
            provider.simulateOccasion(OccasionType.ramadan);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit8) {
            provider.simulateOccasion(OccasionType.eidFitr);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit9) {
            provider.simulateOccasion(OccasionType.arafah);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onLongPress: () => _openSettings(context),
        child: Builder(builder: (ctx) {
          final themePalette = AppTheme.getThemePalette(provider.settings.colorTheme);
          return Scaffold(
            backgroundColor: themePalette.backgroundTop,
            body: Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: themePalette.backgroundGradient,
                  ),
                ),
                // Mandala watermark
                const MandalaBackground(opacity: 0.07),
                // Main content
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(provider, schedule, occasions, themePalette),
                      if (occasions.isNotEmpty)
                        _buildOccasionBanner(occasions.first, schedule),
                      Expanded(
                        child: _buildBody(provider, schedule, themePalette),
                      ),
                      _buildTicker(provider, themePalette),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    ),
  );
}

  Widget _buildHeader(
    DisplayProvider provider,
    PrayerSchedule? schedule,
    List<IslamicOccasion> occasions,
    ThemePalette themePalette,
  ) {
    final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
    final currentWilaya = algerianWilayas.firstWhere(
      (w) => w.code == provider.settings.selectedWilayaCode,
      orElse: () => algerianWilayas.first,
    );
    String? occasionBanner =
        occasions.isNotEmpty ? occasions.first.titleAr : null;
    if (provider.isRamadan && schedule != null && occasions.isNotEmpty) {
      occasionBanner = '🌙 ${occasions.first.titleAr} (الإمساك: ${schedule.imsakFormatted} — الإفطار: ${schedule.iftarFormatted})';
    } else if (provider.isEid && schedule != null && occasions.isNotEmpty) {
      occasionBanner = '🍬 ${occasions.first.titleAr} (صلاة العيد: ${schedule.eidPrayerFormatted})';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: scale.scale(28, min: 16, max: 56),
        vertical: scale.scale(10, min: 6, max: 18),
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: themePalette.borderSoft,
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
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.select ||
                         event.logicalKey == LogicalKeyboardKey.enter ||
                         event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                         event.logicalKey == LogicalKeyboardKey.space ||
                         event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
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
                  color: themePalette.backgroundTop.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(scale.scale(16, min: 12, max: 28)),
                  border: Border.all(
                    color: themePalette.borderSoft,
                    width: scale.scale(1.4, min: 1.0, max: 2.8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: themePalette.glowAccent,
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
                        color: themePalette.primaryAccent,
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
                    _HeaderNavActionButton(
                      icon: Icons.settings,
                      label: 'الإعدادات',
                      tooltip: 'الإعدادات وضبط المواقيت (M / F1)',
                      scale: scale,
                      onPressed: () => _openSettings(context),
                    ),
                    SizedBox(width: scale.scale(6, min: 4, max: 12)),
                    _HeaderNavActionButton(
                      icon: Icons.self_improvement,
                      label: 'الأذكار',
                      tooltip: 'أذكار ما بعد الصلاة (F2 / 5)',
                      scale: scale,
                      onPressed: () => provider.triggerAdhkarOnDemand(),
                    ),
                    SizedBox(width: scale.scale(6, min: 4, max: 12)),
                    _HeaderNavActionButton(
                      icon: Icons.auto_stories,
                      label: 'الأدعية والخطوط',
                      tooltip: 'معرض الأدعية والخطوط الإسلامية (D)',
                      scale: scale,
                      onPressed: () => _openDuaShowcase(context),
                    ),
                    SizedBox(width: scale.scale(6, min: 4, max: 12)),
                    _HeaderNavActionButton(
                      icon: Icons.qr_code_2,
                      label: 'التحكم (QR)',
                      tooltip: 'التحكم اللاسلكي والاقتران بالهاتف (Q)',
                      scale: scale,
                      onPressed: () => _openQrPairing(context),
                    ),
                    SizedBox(width: scale.scale(6, min: 4, max: 12)),
                    _HeaderNavActionButton(
                      icon: Icons.tune,
                      label: 'المحاكاة',
                      tooltip: 'محاكاة الحالات والمناسبات (T / S)',
                      scale: scale,
                      onPressed: () => _openSimulationDialog(context),
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
                        if (provider.settings.showGregorianDate &&
                            provider.gregorianDate.isNotEmpty) ...[
                          SizedBox(height: scale.scale(2, min: 1, max: 4)),
                          Text(
                            provider.gregorianDate,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: scale.scale(17, min: 11, max: 30),
                              fontWeight: FontWeight.w600,
                              color: themePalette.primaryAccent.withValues(alpha: 0.95),
                              shadows: const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                        if (occasionBanner != null) ...[
                          SizedBox(height: scale.scale(2, min: 1, max: 4)),
                          Text(
                            occasionBanner,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: scale.scale(15, min: 10, max: 26),
                              color: AppTheme.goldLight,
                              fontWeight: FontWeight.w600,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
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

  Widget _buildBody(
    DisplayProvider provider,
    PrayerSchedule? schedule,
    ThemePalette themePalette,
  ) {
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

    final effectiveNow = provider.effectiveDate;
    final countdown = provider.countdownToNextAdhan;
    const totalDay = Duration(hours: 24);
    final progress =
        1.0 - (countdown.inSeconds / totalDay.inSeconds).clamp(0.0, 1.0);
    final nextPrayer = schedule.getNextPrayer(effectiveNow);
    final currentPrayer = schedule.getCurrentPrayer(effectiveNow);

    final showFastingTimes = provider.settings.showFastingTimes &&
        (provider.isRamadan || provider.isFastingDay);

    // Compute contextual subtitle and label for Central Gauge
    final nextPrayerTitle = (provider.isFriday && nextPrayer == Prayer.dhuhr)
        ? 'صلاة الجمعة'
        : nextPrayer.nameAr;
    String gaugeSubtitle = 'حتى $nextPrayerTitle';
    String gaugeCenterLabel = DisplayProvider.formatDuration(countdown);
    double gaugeProgress = progress;

    if (provider.isRamadan) {
      if (effectiveNow.isAfter(schedule.fajr) &&
          effectiveNow.isBefore(schedule.maghrib)) {
        final fastingRemaining = schedule.maghrib.difference(effectiveNow);
        if (!fastingRemaining.isNegative) {
          gaugeSubtitle = 'متبقي على موعد الإفطار (المغرب)';
          gaugeCenterLabel = DisplayProvider.formatDuration(fastingRemaining);
          final fastingTotal = schedule.maghrib.difference(schedule.fajr);
          if (fastingTotal.inSeconds > 0) {
            gaugeProgress = (effectiveNow.difference(schedule.fajr).inSeconds /
                    fastingTotal.inSeconds)
                .clamp(0.0, 1.0);
          }
        }
      } else if (effectiveNow.isAfter(schedule.maghrib)) {
        gaugeSubtitle = 'متبقي على موعد الإمساك';
      }
    } else if (provider.isEid) {
      if (effectiveNow.isBefore(schedule.eidPrayer)) {
        final eidRemaining = schedule.eidPrayer.difference(effectiveNow);
        if (!eidRemaining.isNegative && eidRemaining.inHours < 12) {
          gaugeSubtitle = 'حتى صلاة العيد المبارك';
          gaugeCenterLabel = DisplayProvider.formatDuration(eidRemaining);
        } else {
          gaugeSubtitle = 'عيد مبارك وتقبل الله طاعتكم';
        }
      } else {
        gaugeSubtitle = 'عيد مبارك وتقبل الله صالح أعمالكم';
      }
    }

    final template = provider.settings.watchFaceTemplate;
    switch (template) {
      case 'modernHorizontal':
        return _buildModernHorizontalBody(
          provider,
          schedule,
          themePalette,
          currentPrayer,
          nextPrayer,
          gaugeProgress,
          gaugeCenterLabel,
          gaugeSubtitle,
          showFastingTimes,
        );
      case 'grandClock':
        return _buildGrandClockBody(
          provider,
          schedule,
          themePalette,
          currentPrayer,
          nextPrayer,
          gaugeProgress,
          gaugeCenterLabel,
          gaugeSubtitle,
          showFastingTimes,
        );
      case 'traditionalMinbar':
        return _buildTraditionalMinbarBody(
          provider,
          schedule,
          themePalette,
          currentPrayer,
          nextPrayer,
          gaugeProgress,
          gaugeCenterLabel,
          gaugeSubtitle,
          showFastingTimes,
        );
      case 'classicAstrolabe':
      default:
        return _buildClassicAstrolabeBody(
          provider,
          schedule,
          themePalette,
          currentPrayer,
          nextPrayer,
          gaugeProgress,
          gaugeCenterLabel,
          gaugeSubtitle,
          showFastingTimes,
        );
    }
  }

  Widget _buildClassicAstrolabeBody(
    DisplayProvider provider,
    PrayerSchedule schedule,
    ThemePalette themePalette,
    Prayer? currentPrayer,
    Prayer nextPrayer,
    double gaugeProgress,
    String gaugeCenterLabel,
    String gaugeSubtitle,
    bool showFastingTimes,
  ) {
    final leftPrayers = [Prayer.fajr, Prayer.sunrise, Prayer.dhuhr];
    final rightPrayers = [Prayer.asr, Prayer.maghrib, Prayer.isha];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
        final minCol = scale.scaleLayout(180, min: 110);
        final colWidth = (constraints.maxWidth * 0.28).clamp(minCol, scale.is4k ? 700.0 : 420.0);
        final minCard = scale.scaleLayout(160, min: 100);
        final cardWidth = (colWidth * 0.88).clamp(minCard, scale.is4k ? 580.0 : 340.0);
        final maxCenterWidth = constraints.maxWidth - (colWidth * 2);
        final maxSide = (maxCenterWidth < constraints.maxHeight ? maxCenterWidth : constraints.maxHeight);
        final minGauge = scale.scaleLayout(200, min: 140);
        final gaugeSize = (maxSide * 0.82).clamp(minGauge, scale.is4k ? 1000.0 : 520.0);

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
                    final isFajr = p == Prayer.fajr;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: scale.scale(3, min: 1, max: 6)),
                        child: PrayerCardWidget(
                          prayerNameAr: _getPrayerDisplayName(provider, p),
                          time: timeStr,
                          isActive: currentPrayer == p,
                          isNext: nextPrayer == p,
                          width: cardWidth,
                          palette: themePalette,
                          auxiliaryLabel:
                              showFastingTimes && isFajr ? 'الإمساك' : null,
                          auxiliaryTime:
                              showFastingTimes && isFajr ? schedule.imsakFormatted : null,
                        ),
                      ),
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
                  progress: gaugeProgress,
                  centerLabel: gaugeCenterLabel,
                  subtitle: gaugeSubtitle,
                  size: gaugeSize,
                  palette: themePalette,
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
                    final isMaghrib = p == Prayer.maghrib;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: scale.scale(3, min: 1, max: 6)),
                        child: PrayerCardWidget(
                          prayerNameAr: _getPrayerDisplayName(provider, p),
                          time: timeStr,
                          isActive: currentPrayer == p,
                          isNext: nextPrayer == p,
                          width: cardWidth,
                          palette: themePalette,
                          auxiliaryLabel:
                              showFastingTimes && isMaghrib ? 'الإفطار' : null,
                          auxiliaryTime:
                              showFastingTimes && isMaghrib ? schedule.iftarFormatted : null,
                        ),
                      ),
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

  Widget _buildModernHorizontalBody(
    DisplayProvider provider,
    PrayerSchedule schedule,
    ThemePalette themePalette,
    Prayer? currentPrayer,
    Prayer nextPrayer,
    double gaugeProgress,
    String gaugeCenterLabel,
    String gaugeSubtitle,
    bool showFastingTimes,
  ) {
    final allPrayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
        final isNarrowGrid = scale.isNarrow || constraints.maxWidth < 1200;
        final upperGaugeSize = (constraints.maxHeight * (isNarrowGrid ? 0.38 : 0.44)).clamp(160.0, scale.is4k ? 550.0 : 360.0);

        Widget buildPrayerCard(Prayer p) {
          final t = schedule.getTime(p);
          final timeStr =
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
          final isFajr = p == Prayer.fajr;
          final isMagMaghrib = p == Prayer.maghrib;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: scale.scale(4, min: 2, max: 8),
                vertical: isNarrowGrid ? scale.scale(2, min: 1, max: 4) : 0,
              ),
              child: PrayerCardWidget(
                prayerNameAr: _getPrayerDisplayName(provider, p),
                time: timeStr,
                isActive: currentPrayer == p,
                isNext: nextPrayer == p,
                palette: themePalette,
                auxiliaryLabel: showFastingTimes
                    ? (isFajr ? 'الإمساك' : (isMagMaghrib ? 'الإفطار' : null))
                    : null,
                auxiliaryTime: showFastingTimes
                    ? (isFajr ? schedule.imsakFormatted : (isMagMaghrib ? schedule.iftarFormatted : null))
                    : null,
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: scale.scale(20, min: 12, max: 40),
            vertical: scale.scale(8, min: 4, max: 16),
          ),
          child: Column(
            children: [
              // Top countdown & gauge showcase
              Expanded(
                flex: isNarrowGrid ? 4 : 5,
                child: Row(
                  children: [
                    // Next prayer spotlight card
                    Expanded(
                      flex: 3,
                      child: Container(
                        margin: EdgeInsets.all(scale.scale(8, min: 4, max: 14)),
                        padding: EdgeInsets.all(scale.scale(16, min: 12, max: 28)),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              themePalette.primaryAccent.withValues(alpha: 0.20),
                              themePalette.backgroundTop.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(scale.scale(18, min: 12, max: 28)),
                          border: Border.all(color: themePalette.primaryAccent, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: themePalette.glowAccent,
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'الصلاة القادمة: صلاة ${(provider.isFriday && nextPrayer == Prayer.dhuhr) ? 'الجمعة' : nextPrayer.nameAr}',
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: scale.scale(22, min: 16, max: 36),
                                    fontWeight: FontWeight.bold,
                                    color: themePalette.primaryAccent,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                                SizedBox(height: scale.scale(8, min: 4, max: 14)),
                                Text(
                                  gaugeCenterLabel,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: scale.scale(42, min: 28, max: 72),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                SizedBox(height: scale.scale(6, min: 2, max: 10)),
                                Text(
                                  gaugeSubtitle,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: scale.scale(16, min: 12, max: 24),
                                    color: themePalette.textSecondary,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Central circular gauge
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: CircularGaugeWidget(
                          progress: gaugeProgress,
                          centerLabel: gaugeCenterLabel,
                          subtitle: (provider.isFriday && nextPrayer == Prayer.dhuhr)
                              ? 'الجمعة'
                              : nextPrayer.nameAr,
                          size: upperGaugeSize,
                          palette: themePalette,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: scale.scale(8, min: 4, max: 14)),
              // Bottom prayer cards (Row on wide, 2x3 Grid on narrow)
              Expanded(
                flex: isNarrowGrid ? 5 : 4,
                child: isNarrowGrid
                    ? Column(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                buildPrayerCard(Prayer.fajr),
                                buildPrayerCard(Prayer.sunrise),
                                buildPrayerCard(Prayer.dhuhr),
                              ],
                            ),
                          ),
                          SizedBox(height: scale.scale(4, min: 2, max: 6)),
                          Expanded(
                            child: Row(
                              children: [
                                buildPrayerCard(Prayer.asr),
                                buildPrayerCard(Prayer.maghrib),
                                buildPrayerCard(Prayer.isha),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: allPrayers.map(buildPrayerCard).toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrandClockBody(
    DisplayProvider provider,
    PrayerSchedule schedule,
    ThemePalette themePalette,
    Prayer? currentPrayer,
    Prayer nextPrayer,
    double gaugeProgress,
    String gaugeCenterLabel,
    String gaugeSubtitle,
    bool showFastingTimes,
  ) {
    final allPrayers = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
        final gaugeSize = (constraints.maxHeight * (scale.isCompact ? 0.42 : 0.48)).clamp(160.0, scale.is4k ? 600.0 : 380.0);

        return Row(
          children: [
            // Left: Grand Clock & Astrolabe Gauge Focus
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: scale.scale(24, min: 14, max: 40)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Big Digital Time Card
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.scale(32, min: 20, max: 60),
                        vertical: scale.scale(12, min: 8, max: 24),
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themePalette.cardBackground,
                            themePalette.backgroundTop.withValues(alpha: 0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(scale.scale(24, min: 16, max: 36)),
                        border: Border.all(color: themePalette.primaryAccent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: themePalette.glowAccent,
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _timeStr,
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: scale.scale(68, min: 44, max: 120),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: scale.scale(16, min: 10, max: 28)),
                    // Circular countdown gauge
                    CircularGaugeWidget(
                      progress: gaugeProgress,
                      centerLabel: gaugeCenterLabel,
                      subtitle: gaugeSubtitle,
                      size: gaugeSize,
                      palette: themePalette,
                    ),
                  ],
                ),
              ),
            ),
            // Right: Prayer Timetable Column
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: scale.scale(18, min: 10, max: 32),
                  vertical: scale.isCompact
                      ? scale.scale(4, min: 2, max: 8)
                      : scale.scale(10, min: 6, max: 18),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: allPrayers.map((p) {
                    final t = schedule.getTime(p);
                    final timeStr =
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    final isFajr = p == Prayer.fajr;
                    final isMaghrib = p == Prayer.maghrib;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: scale.isCompact
                              ? scale.scale(1, min: 0.5, max: 2)
                              : scale.scale(2, min: 1, max: 4),
                        ),
                        child: PrayerCardWidget(
                          prayerNameAr: _getPrayerDisplayName(provider, p),
                          time: timeStr,
                          isActive: currentPrayer == p,
                          isNext: nextPrayer == p,
                          palette: themePalette,
                          auxiliaryLabel: showFastingTimes
                              ? (isFajr ? 'الإمساك' : (isMaghrib ? 'الإفطار' : null))
                              : null,
                          auxiliaryTime: showFastingTimes
                              ? (isFajr ? schedule.imsakFormatted : (isMaghrib ? schedule.iftarFormatted : null))
                              : null,
                        ),
                      ),
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

  Widget _buildTraditionalMinbarBody(
    DisplayProvider provider,
    PrayerSchedule schedule,
    ThemePalette themePalette,
    Prayer? currentPrayer,
    Prayer nextPrayer,
    double gaugeProgress,
    String gaugeCenterLabel,
    String gaugeSubtitle,
    bool showFastingTimes,
  ) {
    final leftPrayers = [Prayer.fajr, Prayer.sunrise, Prayer.dhuhr];
    final rightPrayers = [Prayer.asr, Prayer.maghrib, Prayer.isha];

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
        final minCol = scale.scaleLayout(180, min: 110);
        final colWidth = (constraints.maxWidth * 0.28).clamp(minCol, scale.is4k ? 700.0 : 420.0);
        final minCard = scale.scaleLayout(160, min: 100);
        final cardWidth = (colWidth * 0.88).clamp(minCard, scale.is4k ? 580.0 : 340.0);
        final crownHeight = scale.scaleLayout(55, min: 35, max: 80);
        final availableHeight = (constraints.maxHeight - crownHeight).clamp(100.0, constraints.maxHeight);
        final maxCenterWidth = constraints.maxWidth - (colWidth * 2);
        final maxSide = (maxCenterWidth < availableHeight ? maxCenterWidth : availableHeight);
        final minGauge = scale.scaleLayout(200, min: 140);
        final gaugeSize = (maxSide * 0.78).clamp(minGauge, scale.is4k ? 950.0 : 480.0);

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: scale.scale(16, min: 10, max: 28),
            vertical: scale.scale(6, min: 4, max: 12),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(scale.isNarrow ? scale.scale(35, min: 20, max: 50) : scale.scale(70, min: 40, max: 100)),
              bottom: Radius.circular(scale.scale(16, min: 12, max: 24)),
            ),
            border: Border.all(
              color: themePalette.primaryAccent.withValues(alpha: 0.45),
              width: 2.0,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                themePalette.primaryAccent.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              // Minbar Arch Crown Header
              Padding(
                padding: EdgeInsets.only(top: scale.scale(8, min: 4, max: 14)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scale.scale(20, min: 14, max: 36),
                        vertical: scale.scale(4, min: 2, max: 8),
                      ),
                      decoration: BoxDecoration(
                        color: themePalette.primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: themePalette.primaryAccent, width: 1.2),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '🕌 مِحْرَابُ الصَّلَاةِ وَالمَوَاقِيتِ المَعْمُورَةِ 🕌',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: scale.scale(16, min: 12, max: 24),
                            fontWeight: FontWeight.bold,
                            color: themePalette.primaryAccent,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    // Left prayers
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: scale.scale(14, min: 8, max: 28)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: leftPrayers.map((p) {
                            final t = schedule.getTime(p);
                            final timeStr =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                            final isFajr = p == Prayer.fajr;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: scale.scale(3, min: 1, max: 6)),
                                child: PrayerCardWidget(
                                  prayerNameAr: _getPrayerDisplayName(provider, p),
                                  time: timeStr,
                                  isActive: currentPrayer == p,
                                  isNext: nextPrayer == p,
                                  width: cardWidth,
                                  palette: themePalette,
                                  auxiliaryLabel:
                                      showFastingTimes && isFajr ? 'الإمساك' : null,
                                  auxiliaryTime:
                                      showFastingTimes && isFajr ? schedule.imsakFormatted : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    // Central Astrolabe
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: CircularGaugeWidget(
                          progress: gaugeProgress,
                          centerLabel: gaugeCenterLabel,
                          subtitle: gaugeSubtitle,
                          size: gaugeSize,
                          palette: themePalette,
                        ),
                      ),
                    ),
                    // Right prayers
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: scale.scale(14, min: 8, max: 28)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: rightPrayers.map((p) {
                            final t = schedule.getTime(p);
                            final timeStr =
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                            final isMaghrib = p == Prayer.maghrib;
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: scale.scale(3, min: 1, max: 6)),
                                child: PrayerCardWidget(
                                  prayerNameAr: _getPrayerDisplayName(provider, p),
                                  time: timeStr,
                                  isActive: currentPrayer == p,
                                  isNext: nextPrayer == p,
                                  width: cardWidth,
                                  palette: themePalette,
                                  auxiliaryLabel:
                                      showFastingTimes && isMaghrib ? 'الإفطار' : null,
                                  auxiliaryTime:
                                      showFastingTimes && isMaghrib ? schedule.iftarFormatted : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTicker(DisplayProvider provider, ThemePalette themePalette) {
    final scale = ScreenScale.of(context, customScale: provider.settings.uiScaleFactor);
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

  void _openQrPairing(BuildContext context) {
    QrPairingDialog.show(context);
  }

  String _getPrayerDisplayName(DisplayProvider provider, Prayer p) {
    if (provider.isFriday && p == Prayer.dhuhr) {
      return 'الجمعة';
    }
    return p.nameAr;
  }

  Widget _buildOccasionBanner(IslamicOccasion occ, PrayerSchedule? schedule) {
    final scale = ScreenScale.of(context);
    String displayText = occ.primaryDuaAr != null
        ? '✦ ${occ.titleAr} ✦   ${occ.primaryDuaAr!}'
        : '✦ ${occ.titleAr} ✦   ${occ.messageAr ?? ""}';

    if (schedule != null) {
      if (occ.type == OccasionType.ramadan) {
        displayText =
            '✦ ${occ.titleAr} ✦   🌙 الإمساك: ${schedule.imsakFormatted}   |   🌴 الإفطار: ${schedule.iftarFormatted}   |   ${occ.primaryDuaAr ?? occ.messageAr ?? ""}';
      } else if (occ.type == OccasionType.eidFitr ||
          occ.type == OccasionType.eidAdha) {
        displayText =
            '✦ ${occ.titleAr} ✦   🕌 موعد صلاة العيد: ${schedule.eidPrayerFormatted} صباحاً   |   ${occ.primaryDuaAr ?? occ.messageAr ?? ""}';
      } else if (occ.type == OccasionType.arafah ||
          occ.type == OccasionType.ashura) {
        displayText =
            '✦ ${occ.titleAr} ✦   🌙 الإمساك: ${schedule.imsakFormatted}   |   🌴 الإفطار: ${schedule.iftarFormatted}   |   ${occ.primaryDuaAr ?? occ.messageAr ?? ""}';
      }
    }

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

class _HeaderNavActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final ScreenScale scale;
  final VoidCallback onPressed;

  const _HeaderNavActionButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.scale,
    required this.onPressed,
  });

  @override
  State<_HeaderNavActionButton> createState() => _HeaderNavActionButtonState();
}

class _HeaderNavActionButtonState extends State<_HeaderNavActionButton> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;
    return Focus(
      onFocusChange: (f) => setState(() => _isFocused = f),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.numpadEnter ||
             event.logicalKey == LogicalKeyboardKey.space ||
             event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: widget.scale.scale(10, min: 7, max: 18),
                vertical: widget.scale.scale(6, min: 4, max: 10),
              ),
              decoration: BoxDecoration(
                color: active
                    ? AppTheme.goldPrimary.withValues(alpha: 0.25)
                    : AppTheme.emeraldMid.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(
                  widget.scale.scale(10, min: 8, max: 16),
                ),
                border: Border.all(
                  color: _isFocused
                      ? AppTheme.focusBorder
                      : (active
                          ? AppTheme.goldPrimary
                          : AppTheme.goldDim.withValues(alpha: 0.55)),
                  width: _isFocused ? 2.2 : 1.1,
                ),
                boxShadow: _isFocused
                    ? [
                        BoxShadow(
                          color: AppTheme.goldPrimary.withValues(alpha: 0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    color: active ? AppTheme.goldPrimary : AppTheme.goldDim,
                    size: widget.scale.scale(20, min: 15, max: 34),
                  ),
                  if (!widget.scale.isNarrow || widget.scale.width >= 1200) ...[
                    SizedBox(width: widget.scale.scale(5, min: 3, max: 10)),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: widget.scale.scale(14, min: 11, max: 24),
                        fontWeight: active ? FontWeight.bold : FontWeight.w600,
                        color: active ? AppTheme.goldPrimary : AppTheme.textPrimary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
