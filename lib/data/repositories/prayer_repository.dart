import '../datasources/bundled_timetable_datasource.dart';
import '../datasources/communes_datasource.dart';
import '../../domain/calculation/algerian_prayer_calculator.dart';
import '../models/prayer_schedule.dart';
import '../models/prayer_offsets.dart';
import '../models/wilaya.dart';
import '../models/commune.dart';

/// Interface contract for Algerian prayer times retrieval.
abstract class IPrayerRepository {
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    Commune? commune,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  });
  Future<List<Wilaya>> getAllWilayas();
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode);
  Future<Commune?> getCommuneByCode(int communeCode);
}

/// Dual-engine implementation:
/// 1. Commune-specific: Astronomical algorithmic calculation using exact municipality coordinates.
/// 2. Primary Wilaya: Bundled official Algerian Ministry timetable data (366 days).
/// 3. Fallback Wilaya: Astronomical algorithmic calculator (AlAdhan Method 19 parameters).
/// 4. Communal calibration: Applied per-prayer manual fine-tuning offsets (±15 min).
class HybridAlgerianPrayerRepository implements IPrayerRepository {
  final IBundledTimetableDataSource _bundledDataSource;
  final ICommunesDataSource _communesDataSource;
  final List<Wilaya> _wilayas;

  HybridAlgerianPrayerRepository({
    required IBundledTimetableDataSource bundledDataSource,
    ICommunesDataSource? communesDataSource,
    List<Wilaya>? wilayas,
  })  : _bundledDataSource = bundledDataSource,
        _communesDataSource = communesDataSource ?? BundledCommunesDataSource(),
        _wilayas = wilayas ?? algerianWilayas;

  @override
  Future<PrayerSchedule> getPrayerTimes({
    required int wilayaCode,
    Commune? commune,
    required DateTime date,
    PrayerOffsets offsets = const PrayerOffsets(),
  }) async {
    PrayerSchedule? schedule;

    // 1. Primary: Official Algerian Ministry bundled timetable + official commune minute offset
    try {
      final wilayaSchedule = await _bundledDataSource.getPrayerSchedule(wilayaCode, date);
      if (wilayaSchedule != null) {
        if (commune != null && commune.minuteOffset != 0) {
          schedule = wilayaSchedule.applyOffsets(PrayerOffsets.uniform(commune.minuteOffset));
        } else {
          schedule = wilayaSchedule;
        }
      }
    } catch (_) {
      schedule = null;
    }

    // 2. Secondary: Astronomical calculation using exact commune coordinates or wilaya center
    if (schedule == null) {
      if (commune != null) {
        schedule = AlgerianPrayerCalculator.calculateForCoordinates(
          latitude: commune.latitude,
          longitude: commune.longitude,
          date: date,
        );
      } else {
        final wilaya = _wilayas.firstWhere(
          (w) => w.code == wilayaCode,
          orElse: () => throw ArgumentError('Wilaya code $wilayaCode not recognized'),
        );
        schedule = AlgerianPrayerCalculator.calculateForWilaya(
          wilaya: wilaya,
          date: date,
        );
      }
    }

    // 3. Communal calibration: Apply per-prayer manual fine-tuning offsets (±15 min)
    return schedule.applyOffsets(offsets);
  }

  @override
  Future<List<Wilaya>> getAllWilayas() async {
    return List.unmodifiable(_wilayas);
  }

  @override
  Future<List<Commune>> getCommunesForWilaya(int wilayaCode) async {
    return _communesDataSource.getCommunesForWilaya(wilayaCode);
  }

  @override
  Future<Commune?> getCommuneByCode(int communeCode) async {
    return _communesDataSource.getCommuneByCode(communeCode);
  }
}
