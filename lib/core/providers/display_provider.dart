import 'package:flutter/foundation.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/mosque_settings.dart';
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
  OccasionType? _activeSimulatedOccasion;

  DisplayProvider({
    required IPrayerRepository prayerRepo,
    MosqueSettings? initialSettings,
  })  : _prayerRepo = prayerRepo,
        _settings = initialSettings ?? const MosqueSettings();

  // ── Getters ────────────────────────────────────────────────────────────────
  MosqueSettings get settings => _settings;
  PrayerSchedule? get todaySchedule => _todaySchedule;
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
  DateTime get effectiveDate => _simulatedDate ?? DateTime.now();
  OccasionType? get activeSimulatedOccasion => _activeSimulatedOccasion;

  List<IslamicOccasion> get activeOccasions =>
      IslamicOccasionsEngine.getOccasions(
        effectiveDate,
        hijriOffsetDays: _settings.hijriOffsetDays,
      );

  IslamicOccasion? get primaryOccasion {
    final list = activeOccasions;
    return list.isNotEmpty ? list.first : null;
  }

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
      _todaySchedule = await _prayerRepo.getPrayerTimes(
        wilayaCode: _settings.selectedWilayaCode,
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
    return schedule.getTimeRemainingToNextPrayer(DateTime.now());
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
  Future<void> simulateOccasion(OccasionType type) async {
    _isSimulationActive = true;
    _activeSimulatedOccasion = type;
    _simulatedDate = IslamicOccasionsEngine.getRepresentativeDate(type);
    await _loadTodaySchedule();
    _refreshHijriDate();
  }

  /// Resets all simulated overrides back to real-world live time.
  Future<void> resetSimulation() async {
    _isSimulationActive = false;
    _isManualStateSimulated = false;
    _simulatedDate = null;
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
