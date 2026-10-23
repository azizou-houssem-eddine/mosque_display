import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/data/models/prayer_offsets.dart';
import 'package:mosque_display/domain/calculation/algerian_prayer_calculator.dart';
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';
import 'package:mosque_display/data/datasources/bundled_timetable_datasource.dart';
import 'package:mosque_display/data/repositories/prayer_repository.dart';

void main() {
  group('Algerian Ministry Method 19 Parity Tests (Benchmark Date 2026-10-06)', () {
    final testDate = DateTime(2026, 10, 6);

    String formatTime(DateTime dt) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }

    test('Wilaya 16 - Alger (الجزائر) matches official Ministry timetable', () {
      final alger = algerianWilayas.firstWhere((w) => w.code == 16);
      final schedule = AlgerianPrayerCalculator.calculateForWilaya(
        wilaya: alger,
        date: testDate,
      );

      expect(formatTime(schedule.fajr), equals('05:21'), reason: 'Fajr mismatch for Alger');
      expect(formatTime(schedule.sunrise), equals('06:47'), reason: 'Sunrise mismatch for Alger');
      expect(formatTime(schedule.dhuhr), equals('12:36'), reason: 'Dhuhr mismatch for Alger (+1 min safety)');
      expect(formatTime(schedule.asr), equals('15:54'), reason: 'Asr mismatch for Alger (Maliki m=1)');
      expect(formatTime(schedule.maghrib), equals('18:24'), reason: 'Maghrib mismatch for Alger');
      expect(formatTime(schedule.isha), equals('19:45'), reason: 'Isha mismatch for Alger (17.0°)');
    });

    test('Wilaya 31 - Oran (وهران) matches official Ministry timetable', () {
      final oran = algerianWilayas.firstWhere((w) => w.code == 31);
      final schedule = AlgerianPrayerCalculator.calculateForWilaya(
        wilaya: oran,
        date: testDate,
      );

      expect(formatTime(schedule.fajr), equals('05:37'), reason: 'Fajr mismatch for Oran');
      expect(formatTime(schedule.sunrise), equals('07:01'), reason: 'Sunrise mismatch for Oran');
      expect(formatTime(schedule.dhuhr), equals('12:51'), reason: 'Dhuhr mismatch for Oran');
      expect(formatTime(schedule.asr), equals('16:09'), reason: 'Asr mismatch for Oran');
      expect(formatTime(schedule.maghrib), equals('18:39'), reason: 'Maghrib mismatch for Oran');
      expect(formatTime(schedule.isha), equals('19:59'), reason: 'Isha mismatch for Oran');
    });

    test('Wilaya 25 - Constantine (قسنطينة) matches official Ministry timetable', () {
      final constantine = algerianWilayas.firstWhere((w) => w.code == 25);
      final schedule = AlgerianPrayerCalculator.calculateForWilaya(
        wilaya: constantine,
        date: testDate,
      );

      expect(formatTime(schedule.fajr), equals('05:07'), reason: 'Fajr mismatch for Constantine');
      expect(formatTime(schedule.sunrise), equals('06:33'), reason: 'Sunrise mismatch for Constantine');
      expect(formatTime(schedule.dhuhr), equals('12:22'), reason: 'Dhuhr mismatch for Constantine');
      expect(formatTime(schedule.asr), equals('15:40'), reason: 'Asr mismatch for Constantine');
      expect(formatTime(schedule.maghrib), equals('18:10'), reason: 'Maghrib mismatch for Constantine');
      expect(formatTime(schedule.isha), equals('19:30'), reason: 'Isha mismatch for Constantine');
    });

    test('Wilaya 30 - Ouargla (ورقلة) matches official Ministry timetable', () {
      final ouargla = algerianWilayas.firstWhere((w) => w.code == 30);
      final schedule = AlgerianPrayerCalculator.calculateForWilaya(
        wilaya: ouargla,
        date: testDate,
      );

      expect(formatTime(schedule.fajr), equals('05:15'), reason: 'Fajr mismatch for Ouargla');
      expect(formatTime(schedule.sunrise), equals('06:36'), reason: 'Sunrise mismatch for Ouargla');
      expect(formatTime(schedule.dhuhr), equals('12:27'), reason: 'Dhuhr mismatch for Ouargla');
      expect(formatTime(schedule.asr), equals('15:47'), reason: 'Asr mismatch for Ouargla');
      expect(formatTime(schedule.maghrib), equals('18:17'), reason: 'Maghrib mismatch for Ouargla');
      expect(formatTime(schedule.isha), equals('19:34'), reason: 'Isha mismatch for Ouargla');
    });

    test('Geographical East-to-West gradient holds strictly across Algeria', () {
      final constantine = algerianWilayas.firstWhere((w) => w.code == 25); // East
      final alger = algerianWilayas.firstWhere((w) => w.code == 16);       // Center
      final oran = algerianWilayas.firstWhere((w) => w.code == 31);        // West

      final cstSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: constantine, date: testDate);
      final algSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: testDate);
      final oraSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: oran, date: testDate);

      // East occurs strictly earlier than Center, which occurs earlier than West
      expect(cstSchedule.fajr.isBefore(algSchedule.fajr), isTrue);
      expect(algSchedule.fajr.isBefore(oraSchedule.fajr), isTrue);

      expect(cstSchedule.dhuhr.isBefore(algSchedule.dhuhr), isTrue);
      expect(algSchedule.dhuhr.isBefore(oraSchedule.dhuhr), isTrue);

      expect(cstSchedule.maghrib.isBefore(algSchedule.maghrib), isTrue);
      expect(algSchedule.maghrib.isBefore(oraSchedule.maghrib), isTrue);

      // Total national span is approximately 29-30 minutes
      final diffMinutes = oraSchedule.maghrib.difference(cstSchedule.maghrib).inMinutes;
      expect(diffMinutes, equals(29));
    });

    test('Chronological sequence invariant holds for all calculated schedules', () {
      for (final code in [16, 31, 25, 30]) {
        final wilaya = algerianWilayas.firstWhere((w) => w.code == code);
        final s = AlgerianPrayerCalculator.calculateForWilaya(wilaya: wilaya, date: testDate);

        expect(s.fajr.isBefore(s.sunrise), isTrue);
        expect(s.sunrise.isBefore(s.dhuhr), isTrue);
        expect(s.dhuhr.isBefore(s.asr), isTrue);
        expect(s.asr.isBefore(s.maghrib), isTrue);
        expect(s.maghrib.isBefore(s.isha), isTrue);
      }
    });
  });

  group('Communal Calibration Offsets Tests', () {
    final testDate = DateTime(2026, 10, 6);
    final alger = algerianWilayas.firstWhere((w) => w.code == 16);

    test('Offsets shift prayer times accurately', () {
      final baseSchedule = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: testDate);
      const offsets = PrayerOffsets(fajr: 5, sunrise: 0, dhuhr: -3, asr: 2, maghrib: 1, isha: 10);
      final calibrated = baseSchedule.applyOffsets(offsets);

      expect(calibrated.fajr.difference(baseSchedule.fajr).inMinutes, equals(5));
      expect(calibrated.dhuhr.difference(baseSchedule.dhuhr).inMinutes, equals(-3));
      expect(calibrated.asr.difference(baseSchedule.asr).inMinutes, equals(2));
      expect(calibrated.maghrib.difference(baseSchedule.maghrib).inMinutes, equals(1));
      expect(calibrated.isha.difference(baseSchedule.isha).inMinutes, equals(10));
    });

    test('Offset values are clamped within [-15, +15] minutes boundary', () {
      final offsets = const PrayerOffsets().copyWith(fajr: 30, isha: -25);
      expect(offsets.fajr, equals(15));
      expect(offsets.isha, equals(-15));

      final fromJsonOffsets = PrayerOffsets.fromJson(const {'fajr': 30, 'isha': -25});
      expect(fromJsonOffsets.fajr, equals(15));
      expect(fromJsonOffsets.isha, equals(-15));
    });
  });

  group('Hijri Calendar Engine Tests', () {
    final testDate = DateTime(2026, 10, 6); // Tuesday

    test('Converts Gregorian 2026-10-06 to 25 Rabi al-Thani 1448 AH', () {
      final hijriDate = HijriCalculator.calculate(gregorianDate: testDate, offsetDays: 0);

      expect(hijriDate.year, equals(1448));
      expect(hijriDate.month, equals(4));
      expect(hijriDate.day, equals(25));
      expect(hijriDate.monthNameAr, equals('ربيع الثاني'));
      expect(hijriDate.dayNameAr, equals('الثلاثاء'));
      expect(hijriDate.formattedAr, equals('25 ربيع الثاني 1448 هـ'));
      expect(hijriDate.fullFormattedAr, equals('الثلاثاء، 25 ربيع الثاني 1448 هـ'));
    });

    test('Moonsighting adjustment +1 day shifts to 26 Rabi al-Thani', () {
      final hijriDate = HijriCalculator.calculate(gregorianDate: testDate, offsetDays: 1);
      expect(hijriDate.day, equals(26));
      expect(hijriDate.formattedAr, equals('26 ربيع الثاني 1448 هـ'));
    });

    test('Moonsighting adjustment -1 day shifts to 24 Rabi al-Thani', () {
      final hijriDate = HijriCalculator.calculate(gregorianDate: testDate, offsetDays: -1);
      expect(hijriDate.day, equals(24));
      expect(hijriDate.formattedAr, equals('24 ربيع الثاني 1448 هـ'));
    });

    test('Eastern Arabic numeral converter converts digits accurately', () {
      expect(HijriCalculator.toEasternArabicDigits('1448'), equals('١٤٤٨'));
      expect(HijriCalculator.toEasternArabicDigits('25'), equals('٢٥'));
    });
  });

  group('HybridAlgerianPrayerRepository Dual-Engine Tests', () {
    final testDate = DateTime(2026, 10, 6);

    test('Uses primary bundled datasource when available', () async {
      final fakeCache = {
        '16': {
          '10-06': ['05:21', '06:47', '12:36', '15:54', '18:24', '19:45']
        }
      };
      final dataSource = BundledTimetableDataSource(initialCache: fakeCache);
      final repository = HybridAlgerianPrayerRepository(bundledDataSource: dataSource);

      final schedule = await repository.getPrayerTimes(wilayaCode: 16, date: testDate);
      expect(schedule.fajr.hour, equals(5));
      expect(schedule.fajr.minute, equals(21));
    });

    test('Seamlessly falls back to astronomical calculation when date/wilaya missing', () async {
      // Empty bundled cache simulates missing date/asset
      final emptyDataSource = BundledTimetableDataSource(initialCache: {});
      final repository = HybridAlgerianPrayerRepository(bundledDataSource: emptyDataSource);

      final schedule = await repository.getPrayerTimes(wilayaCode: 16, date: testDate);
      expect(schedule.fajr.hour, equals(5));
      expect(schedule.fajr.minute, equals(21));
      expect(schedule.dhuhr.hour, equals(12));
      expect(schedule.dhuhr.minute, equals(36));
      expect(schedule.asr.hour, equals(15));
      expect(schedule.asr.minute, equals(54));
    });

    test('Applies communal calibration offsets on top of repository schedule', () async {
      final emptyDataSource = BundledTimetableDataSource(initialCache: {});
      final repository = HybridAlgerianPrayerRepository(bundledDataSource: emptyDataSource);

      const offsets = PrayerOffsets(fajr: 4);
      final schedule = await repository.getPrayerTimes(wilayaCode: 16, date: testDate, offsets: offsets);
      expect(schedule.fajr.minute, equals(25)); // 05:21 + 4 min = 05:25
    });
  });
}
