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

/// Hybrid repository implementation conforming strictly to Algerian Ministry (MARW/CRAAG):
/// 1. Primary: Bundled official Algerian Ministry timetable data (366 days for all 58 Wilayas).
/// 2. Commune strategy: Official ministerial minute difference (فروق التوقيت بالدقائق) applied to Wilaya schedule.
/// 3. Fallback: Astronomical algorithmic calculator (AlAdhan Method 19 parameters).
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
    PrayerSchedule? baseSchedule;

    // 1. Primary: Load bundled official Algerian Ministry timetable for the Wilaya (366 days)
    try {
      baseSchedule = await _bundledDataSource.getPrayerSchedule(wilayaCode, date);
    } catch (_) {
      baseSchedule = null;
    }

    // 2. Fallback: Astronomical calculation if bundled lookup failed
    if (baseSchedule == null) {
      if (commune != null) {
        baseSchedule = AlgerianPrayerCalculator.calculateForCoordinates(
          latitude: commune.latitude,
          longitude: commune.longitude,
          date: date,
        );
      } else {
        final wilaya = _wilayas.firstWhere(
          (w) => w.code == wilayaCode,
          orElse: () => throw ArgumentError('Wilaya code $wilayaCode not recognized'),
        );
        baseSchedule = AlgerianPrayerCalculator.calculateForWilaya(
          wilaya: wilaya,
          date: date,
        );
      }
    } else if (commune != null && commune.minuteOffset != 0) {
      // 3. Official Algerian Ministry standard (marw.dz / CRAAG):
      // Commune prayer times are obtained by applying the official minute difference
      // (فروق التوقيت بالدقائق) relative to the Wilaya's official timetable.
      baseSchedule = baseSchedule.applyOffsets(PrayerOffsets.uniform(commune.minuteOffset));
    }

    // 4. Communal calibration: Apply per-prayer manual fine-tuning offsets (±15 min)
    return baseSchedule.applyOffsets(offsets);
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
