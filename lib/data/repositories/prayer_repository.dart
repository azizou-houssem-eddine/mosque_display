import '../datasources/bundled_timetable_datasource.dart';
import '../../domain/calculation/algerian_prayer_calculator.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_offsets.dart';
import '../models/wilaya.dart';

/// Interface contract for Algerian prayer times retrieval.
abstract class IPrayerRepository {
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  });
  Future<List<Wilaya>> getAllWilayas();
}

/// Dual-engine implementation:
/// 1. Primary: Bundled official Algerian Ministry timetable data (366 days).
/// 2. Fallback: Astronomical algorithmic calculator (AlAdhan Method 19 parameters).
/// 3. Communal calibration: Applied per-prayer manual fine-tuning offsets (±15 min).
class HybridAlgerianPrayerRepository implements IPrayerRepository {
  final IBundledTimetableDataSource _bundledDataSource;
  final List<Wilaya> _wilayas;

  HybridAlgerianPrayerRepository({
    required IBundledTimetableDataSource bundledDataSource,
    List<Wilaya>? wilayas,
  })  : _bundledDataSource = bundledDataSource,
        _wilayas = wilayas ?? algerianWilayas;

  @override
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  }) async {
    // 1. Primary: Bundled official Algerian Ministry timetable
    PrayerSchedule? schedule;
    try {
      schedule = await _bundledDataSource.getPrayerSchedule(wilayaCode, date);
    } catch (_) {
      schedule = null;
    }

    // 2. Fallback: Astronomical algorithmic calculator (Method 19)
    if (schedule == null) {
      final wilaya = _wilayas.firstWhere(
        (w) => w.code == wilayaCode,
        orElse: () => throw ArgumentError('Wilaya code $wilayaCode not recognized'),
      );
      schedule = AlgerianPrayerCalculator.calculateForWilaya(
        wilaya: wilaya,
        date: date,
      );
    }

    // 3. Communal calibration: Apply per-prayer manual fine-tuning offsets (±15 min)
    return schedule.applyOffsets(offsets);
  }

  @override
  Future<List<Wilaya>> getAllWilayas() async {
    return List.unmodifiable(_wilayas);
  }
}
