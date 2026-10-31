import 'package:flutter/foundation.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/mosque_settings.dart';
import '../../data/models/commune.dart';
import '../../data/repositories/prayer_repository.dart';
import '../../domain/calculation/hijri_calculator.dart';
import '../../domain/occasions/islamic_occasions_engine.dart';

/// Display states the TV cycles through during a prayer day.
enum DisplayState {
  standard, // Clock, prayer cards, countdown gauge, ticker
  adhanAlert, // Prayer time entered — visual pulse
  iqamahCountdown, // Counting down to Iqamah start
  salatBlackout, // Congregational prayer in progress — screen blackout
  postSalatAdhkar, // 7-min post-prayer Adhkar carousel
}

/// Central state provider for the mosque display app.
/// Manages prayer schedule, current time, display state transitions,
/// settings, and Hijri date.
class DisplayProvider extends ChangeNotifier {
  final IPrayerRepository _prayerRepo;

  // ── State ──────────────────────────────────────────────────────────────────
  MosqueSettings _settings;
  PrayerSchedule? _todaySchedule;
  Commune? _activeCommune;
  DisplayState _displayState = DisplayState.standard;
  Prayer? _activePrayer;
  Duration _iqamahRemaining = Duration.zero;
  Duration _blackoutRemaining = Duration.zero;
  Duration _adhkarRemaining = Duration.zero;
  String _hijriDate = '';
  bool _isLoading = true;
  String? _error;

  // On-demand Adhkar shortcut (D-pad menu trigger)
  bool _adhkarShortcutActive = false;

  // ── Simulation / Testing State ──────────────────────────────────────────────
  bool _isSimulationActive = false;
  bool _isManualStateSimulated = false;
  DateTime? _simulatedDate;
  DateTime? _simulatedAnchorTime;
  DateTime? _simulationStartedAt;
  OccasionType? _activeSimulatedOccasion;

  DisplayProvider({
    required IPrayerRepository prayerRepo,
    MosqueSettings? initialSettings,
  })  : _prayerRepo = prayerRepo,
        _settings = initialSettings ?? const MosqueSettings();

  // ── Getters ────────────────────────────────────────────────────────────────
  IPrayerRepository get prayerRepo => _prayerRepo;
  MosqueSettings get settings => _settings;
  PrayerSchedule? get todaySchedule => _todaySchedule;
  Commune? get activeCommune => _activeCommune;
  DisplayState get displayState => _displayState;
  Prayer? get activePrayer => _activePrayer;
  Duration get iqamahRemaining => _iqamahRemaining;
  Duration get blackoutRemaining => _blackoutRemaining;
  Duration get adhkarRemaining => _adhkarRemaining;
  String get hijriDate => _hijriDate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get adhkarShortcutActive => _adhkarShortcutActive;
  bool get isSimulationActive => _isSimulationActive;

  /// Effective date-time currently active, normalized to Algerian National Time (UTC+1).
  /// When simulation is active, anchors to the simulated representative time
  /// and ticks synchronously second-by-second for live TV inspection.
  DateTime get effectiveDate {
    if (_simulatedDate != null) {
      final base = _simulatedAnchorTime ?? _simulatedDate!;
      final elapsed = _simulationStartedAt != null
          ? DateTime.now().difference(_simulationStartedAt!)
          : Duration.zero;
      return base.add(elapsed);
    }
    final algeriaUtc = DateTime.now().toUtc().add(const Duration(hours: 1));
    return DateTime(
      algeriaUtc.year,
      algeriaUtc.month,
      algeriaUtc.day,
      algeriaUtc.hour,
      algeriaUtc.minute,
      algeriaUtc.second,
      algeriaUtc.millisecond,
      algeriaUtc.microsecond,
    );
  }

  OccasionType? get activeSimulatedOccasion => _activeSimulatedOccasion;

  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) {
    return _prayerRepo.getCommunesForWilaya(wilayaCode);
  }

  List<IslamicOccasion> get activeOccasions {
    final list = IslamicOccasionsEngine.getOccasions(
      effectiveDate,
      hijriOffsetDays: _settings.hijriOffsetDays,
    );
    if (_activeSimulatedOccasion != null) {
      final idx = list.indexWhere((o) => o.type == _activeSimulatedOccasion);
      if (idx > 0) {
        final occ = list.removeAt(idx);
        list.insert(0, occ);
      } else if (idx == -1) {
        final occ = IslamicOccasionsEngine.getOccasionForType(
          _activeSimulatedOccasion!,
          date: effectiveDate,
          hijriOffsetDays: _settings.hijriOffsetDays,
        );
        list.insert(0, occ);
      }
    }
    return list;
  }

  IslamicOccasion? get primaryOccasion {
    final list = activeOccasions;
    return list.isNotEmpty ? list.first : null;
  }

  bool get isRamadan {
    if (_activeSimulatedOccasion == OccasionType.ramadan) return true;
    final hijri = HijriCalculator.calculate(
      gregorianDate: effectiveDate,
      offsetDays: _settings.hijriOffsetDays,
    );
    return hijri.month == 9;
  }

  bool get isEid {
    if (_activeSimulatedOccasion == OccasionType.eidFitr ||
        _activeSimulatedOccasion == OccasionType.eidAdha) {
      return true;
    }
    return activeOccasions.any(
      (o) => o.type == OccasionType.eidFitr || o.type == OccasionType.eidAdha,
    );
  }

  bool get isFastingDay {
    if (isRamadan) return true;
    return activeOccasions.any(
      (o) => o.type == OccasionType.arafah || o.type == OccasionType.ashura,
    );
  }

  DateTime? get imsakTime => _todaySchedule?.imsak;
  DateTime? get iftarTime => _todaySchedule?.iftar;
  DateTime? get eidPrayerTime => _todaySchedule?.eidPrayer;

  List<String> get occasionDuas {
    final list = activeOccasions;
    final results = <String>[];
    for (final occ in list) {
      results.addAll(occ.duasAr);
    }
    return results;
  }

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    await _loadTodaySchedule();
    _refreshHijriDate();
  }

  Future<void> _loadTodaySchedule() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final now = effectiveDate;
      if (_settings.selectedCommuneCode != null) {
        _activeCommune = await _prayerRepo.getCommuneByCode(_settings.selectedCommuneCode!);
      } else {
        _activeCommune = null;
      }

      _todaySchedule = await _prayerRepo.getPrayerTimes(
        wilayaCode: _settings.selectedWilayaCode,
        commune: _activeCommune,
        date: now,
        offsets: _settings.offsets,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _refreshHijriDate() {
    final now = effectiveDate;
    final hijri = HijriCalculator.calculate(
      gregorianDate: now,
      offsetDays: _settings.hijriOffsetDays,
    );
    _hijriDate = hijri.fullFormattedAr;
    notifyListeners();
  }

  // ── Tick (called by timer, once per second) ────────────────────────────────
  void tick() {
    final now = effectiveDate;
    // Midnight crossover — reload schedule
    if (now.hour == 0 && now.minute == 0 && now.second == 0) {
      _loadTodaySchedule();
      _refreshHijriDate();
    }
    _evaluateStateTransitions(now);
    notifyListeners();
  }

  void _evaluateStateTransitions(DateTime now) {
    if (_isManualStateSimulated) {
      // In manual simulation mode, decrement simulated timers
      switch (_displayState) {
        case DisplayState.iqamahCountdown:
          if (_iqamahRemaining.inSeconds > 0) {
            _iqamahRemaining -= const Duration(seconds: 1);
          } else {
            _blackoutRemaining =
                Duration(minutes: _settings.blackoutDurationMinutes);
            _displayState = DisplayState.salatBlackout;
          }
          break;
        case DisplayState.salatBlackout:
          if (_blackoutRemaining.inSeconds > 0) {
            _blackoutRemaining -= const Duration(seconds: 1);
          } else {
            _adhkarRemaining = const Duration(minutes: 7);
            _displayState = DisplayState.postSalatAdhkar;
          }
          break;
        case DisplayState.postSalatAdhkar:
          if (_adhkarRemaining.inSeconds > 0) {
            _adhkarRemaining -= const Duration(seconds: 1);
          } else {
            _dismissAdhkar();
          }
          break;
        default:
          break;
      }
      return;
    }

    final schedule = _todaySchedule;
    if (schedule == null) return;

    switch (_displayState) {
      case DisplayState.standard:
        _checkForAdhanEntry(schedule, now);
        break;
      case DisplayState.adhanAlert:
        _checkAdhanToIqamah(schedule, now);
        break;
      case DisplayState.iqamahCountdown:
        _tickIqamah(now);
        break;
      case DisplayState.salatBlackout:
        _tickBlackout(now);
        break;
      case DisplayState.postSalatAdhkar:
        _tickAdhkar(now);
        break;
    }
  }

  void _checkForAdhanEntry(PrayerSchedule schedule, DateTime now) {
    for (final prayer in Prayer.values) {
      if (!prayer.isSalat) continue;
      final pTime = schedule.getTime(prayer);
      // Within ±30 seconds of prayer time
      if ((now.difference(pTime).inSeconds).abs() <= 30 &&
          now.isAfter(pTime.subtract(const Duration(seconds: 30)))) {
        _activePrayer = prayer;
        _displayState = DisplayState.adhanAlert;
        return;
      }
    }
  }

  void _checkAdhanToIqamah(PrayerSchedule schedule, DateTime now) {
    final prayer = _activePrayer;
    if (prayer == null) return;
    final pTime = schedule.getTime(prayer);
    // After 90 sec Adhan display, switch to Iqamah countdown
    final iqamahDelay = Duration(minutes: _settings.iqamahDelays.getDelayFor(prayer));
    final iqamahTime = pTime.add(iqamahDelay);
    if (now.isAfter(pTime.add(const Duration(seconds: 90)))) {
      _iqamahRemaining = iqamahTime.difference(now);
      if (_iqamahRemaining.isNegative) _iqamahRemaining = Duration.zero;
      _displayState = DisplayState.iqamahCountdown;
    }
  }

  void _tickIqamah(DateTime now) {
    final prayer = _activePrayer;
    if (prayer == null) return;
    final schedule = _todaySchedule!;
    final pTime = schedule.getTime(prayer);
    final iqamahDelay = Duration(minutes: _settings.iqamahDelays.getDelayFor(prayer));
    final iqamahTime = pTime.add(iqamahDelay);
    _iqamahRemaining = iqamahTime.difference(now);
    if (_iqamahRemaining.isNegative || _iqamahRemaining == Duration.zero) {
      _iqamahRemaining = Duration.zero;
      _blackoutRemaining =
          Duration(minutes: _settings.blackoutDurationMinutes);
      _displayState = DisplayState.salatBlackout;
    }
  }

  void _tickBlackout(DateTime now) {
    if (_blackoutRemaining.inSeconds > 0) {
      _blackoutRemaining -= const Duration(seconds: 1);
    } else {
      _adhkarRemaining = const Duration(minutes: 7);
      _displayState = DisplayState.postSalatAdhkar;
    }
  }

  void _tickAdhkar(DateTime now) {
    if (_adhkarShortcutActive || _adhkarRemaining.inSeconds > 0) {
      if (_adhkarRemaining.inSeconds > 0) {
        _adhkarRemaining -= const Duration(seconds: 1);
      } else {
        _dismissAdhkar();
      }
    }
  }

  // ── Public Actions ─────────────────────────────────────────────────────────

  /// D-pad shortcut: trigger Adhkar on demand.
  void triggerAdhkarOnDemand() {
    _adhkarShortcutActive = true;
    _adhkarRemaining = const Duration(minutes: 7);
    _displayState = DisplayState.postSalatAdhkar;
    notifyListeners();
  }

  /// D-pad Back: dismiss Adhkar early.
  void dismissAdhkar() {
    _dismissAdhkar();
    notifyListeners();
  }

  /// Dismisses any active prayer state (Adhan alert, Iqamah countdown, Blackout, Adhkar)
  /// and returns to the standard dashboard view.
  void dismissActiveState() {
    if (_isSimulationActive) {
      resetSimulation();
      return;
    }
    _adhkarShortcutActive = false;
    _iqamahRemaining = Duration.zero;
    _blackoutRemaining = Duration.zero;
    _adhkarRemaining = Duration.zero;
    _activePrayer = null;
    _displayState = DisplayState.standard;
    notifyListeners();
  }

  void _dismissAdhkar() {
    _adhkarShortcutActive = false;
    _adhkarRemaining = Duration.zero;
    _activePrayer = null;
    _displayState = DisplayState.standard;
  }

  /// Update settings (from settings screen) and reload.
  Future<void> updateSettings(MosqueSettings newSettings) async {
    _settings = newSettings;
    await _loadTodaySchedule();
    _refreshHijriDate();
  }

  /// Countdown to next Adhan from now.
  Duration get countdownToNextAdhan {
    final schedule = _todaySchedule;
    if (schedule == null) return Duration.zero;
    return schedule.getTimeRemainingToNextPrayer(effectiveDate);
  }

  /// Format duration as "HH:MM:SS".
  static String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Format duration as "MM:SS" (for Iqamah countdown).
  static String formatMinSec(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Testing & Simulation Methods ────────────────────────────────────────────

  /// Simulates a specific display state on-demand for testing.
  void simulateDisplayState(
    DisplayState state, {
    Prayer prayer = Prayer.maghrib,
    Duration? customDuration,
  }) {
    _isSimulationActive = true;
    _isManualStateSimulated = true;
    _activePrayer = prayer;
    _displayState = state;

    switch (state) {
      case DisplayState.standard:
        _iqamahRemaining = Duration.zero;
        _blackoutRemaining = Duration.zero;
        _adhkarRemaining = Duration.zero;
        break;
      case DisplayState.adhanAlert:
        break;
      case DisplayState.iqamahCountdown:
        _iqamahRemaining = customDuration ?? const Duration(minutes: 5);
        break;
      case DisplayState.salatBlackout:
        _blackoutRemaining = customDuration ??
            Duration(minutes: _settings.blackoutDurationMinutes);
        break;
      case DisplayState.postSalatAdhkar:
        _adhkarRemaining = customDuration ?? const Duration(minutes: 7);
        break;
    }
    notifyListeners();
  }

  /// Simulates a specific religious occasion by date manipulation.
  /// Anchors the clock to a realistic daytime hour and advances second-by-second.
  Future<void> simulateOccasion(
    OccasionType type, {
    DateTime? customDateTime,
  }) async {
    _isSimulationActive = true;
    _isManualStateSimulated = false;
    _activeSimulatedOccasion = type;
    final repDate = customDateTime ?? IslamicOccasionsEngine.getRepresentativeDate(type);
    _simulatedDate = repDate;
    _simulatedAnchorTime = repDate;
    _simulationStartedAt = DateTime.now();
    _displayState = DisplayState.standard;
    _activePrayer = null;
    await _loadTodaySchedule();
    _refreshHijriDate();
  }

  /// Resets all simulated overrides back to real-world live time.
  Future<void> resetSimulation() async {
    _isSimulationActive = false;
    _isManualStateSimulated = false;
    _simulatedDate = null;
    _simulatedAnchorTime = null;
    _simulationStartedAt = null;
    _activeSimulatedOccasion = null;
    _displayState = DisplayState.standard;
    _activePrayer = null;
    _iqamahRemaining = Duration.zero;
    _blackoutRemaining = Duration.zero;
    _adhkarRemaining = Duration.zero;
    await _loadTodaySchedule();
    _refreshHijriDate();
  }
}
