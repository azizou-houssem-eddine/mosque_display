import 'package:adhan/adhan.dart';
import '../../data/models/prayer_schedule.dart';
import '../../data/models/wilaya.dart';

/// Calculation engine for Algerian prayer times following official standards
/// set by the Ministry of Religious Affairs and Wakfs (MARW / CRAAG).
///
/// Implements AlAdhan Method ID 19 parameters:
/// - Fajr: 18.0° solar depression angle
/// - Isha: 17.0° solar depression angle
/// - Madhab: Maliki standard (shadow factor = 1.0, Madhab.shafi in adhan)
/// - Dhuhr & Maghrib: Astronomical transit and sunset with ministerial safety margins
/// - Asr: Calibrated to Algerian ministerial standards (lat >= 36° +2 min, lat < 36° +1 min)
/// - Timezone: Constant UTC+1 (West Africa Time, DST abolished since 1981)
class AlgerianPrayerCalculator {
  /// Algerian national standard timezone offset: UTC+1
  static const Duration algerianTimeZoneOffset = Duration(hours: 1);

  /// Builds CalculationParameters conforming to Algerian Method 19 standards.
  static CalculationParameters getAlgerianParameters({double latitude = 36.7538}) {
    final params = CalculationParameters(fajrAngle: 18.0, ishaAngle: 17.0);
    params.madhab = Madhab.shafi; // Maliki / Shafi factor = 1.0
    params.highLatitudeRule = HighLatitudeRule.middle_of_the_night;
    // Ministerial Asr calibration:
    params.adjustments.asr = latitude >= 36.0 ? 2 : 1;
    return params;
  }

  /// Calculates prayer times for specific coordinates and date, normalized to UTC+1.
  static PrayerSchedule calculateForCoordinates({
    required double latitude,
    required double longitude,
    required DateTime date,
    Duration targetTimeZoneOffset = algerianTimeZoneOffset,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final dateComponents = DateComponents(date.year, date.month, date.day);
    final params = getAlgerianParameters(latitude: latitude);
    final rawTimes = PrayerTimes(
      coordinates,
      dateComponents,
      params,
      utcOffset: targetTimeZoneOffset,
    );

    return PrayerSchedule.fromAdhan(
      rawTimes,
      date,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
  }

  /// Calculates prayer times for a verified Wilaya.
  static PrayerSchedule calculateForWilaya({
    required Wilaya wilaya,
    required DateTime date,
    Duration targetTimeZoneOffset = algerianTimeZoneOffset,
  }) {
    return calculateForCoordinates(
      latitude: wilaya.latitude,
      longitude: wilaya.longitude,
      date: date,
      targetTimeZoneOffset: targetTimeZoneOffset,
    );
  }
}
