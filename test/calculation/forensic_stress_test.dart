import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mosque_display/data/models/wilaya.dart';
import 'package:mosque_display/domain/calculation/algerian_prayer_calculator.dart';
import 'package:mosque_display/domain/calculation/hijri_calculator.dart';

void main() {
  group('Forensic Stress Test: Perpetual Dataset Verification', () {
    test('assets/data/wilayas.json contains 58 valid Wilayas', () {
      final file = File('assets/data/wilayas.json');
      expect(file.existsSync(), isTrue, reason: 'wilayas.json must exist');

      final content = file.readAsStringSync();
      final list = json.decode(content) as List<dynamic>;
      expect(list.length, equals(58), reason: 'Must contain exactly 58 wilayas');

      final codes = <int>{};
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final code = map['code'] as int;
        final lat = (map['latitude'] as num).toDouble();
        final lng = (map['longitude'] as num).toDouble();
        final nameAr = map['nameAr'] as String;
        final nameFr = map['nameFr'] as String;

        expect(code >= 1 && code <= 58, isTrue);
        expect(lat >= 18.0 && lat <= 38.0, isTrue, reason: 'Lat out of range for $code');
        expect(lng >= -9.0 && lng <= 12.0, isTrue, reason: 'Lng out of range for $code');
        expect(nameAr.trim().isNotEmpty, isTrue);
        expect(nameFr.trim().isNotEmpty, isTrue);
        codes.add(code);
      }
      expect(codes.length, equals(58), reason: 'All 58 codes must be unique');
    });

    test('assets/data/algerian_prayer_times.json contains complete perpetual timetables', () {
      final file = File('assets/data/algerian_prayer_times.json');
      expect(file.existsSync(), isTrue, reason: 'algerian_prayer_times.json must exist');

      final content = file.readAsStringSync();
      final data = json.decode(content) as Map<String, dynamic>;
      expect(data.length, equals(58), reason: 'Must contain all 58 Wilaya keys');

      for (int w = 1; w <= 58; w++) {
        final wilayaKey = w.toString();
        expect(data.containsKey(wilayaKey), isTrue, reason: 'Missing wilaya $w');

        final wData = data[wilayaKey] as Map<String, dynamic>;
        expect(wData.length, equals(366), reason: 'Wilaya $w must have 366 days');

        // Check leap day
        expect(wData.containsKey('02-29'), isTrue, reason: 'Wilaya $w missing 02-29');

        // Spot check times format and ordering for key dates
        for (final dayKey in ['01-01', '02-29', '06-21', '10-06', '12-31']) {
          final times = wData[dayKey] as List<dynamic>;
          expect(times.length, equals(6), reason: 'Wilaya $w on $dayKey must have 6 times');

          final parsedMinutes = times.map((t) {
            final parts = (t as String).split(':');
            return int.parse(parts[0]) * 60 + int.parse(parts[1]);
          }).toList();

          // Invariant: Fajr < Sunrise < Dhuhr < Asr < Maghrib < Isha
          expect(parsedMinutes[0] < parsedMinutes[1], isTrue, reason: 'Fajr < Sunrise failed for W$w on $dayKey');
          expect(parsedMinutes[1] < parsedMinutes[2], isTrue, reason: 'Sunrise < Dhuhr failed for W$w on $dayKey');
          expect(parsedMinutes[2] < parsedMinutes[3], isTrue, reason: 'Dhuhr < Asr failed for W$w on $dayKey');
          expect(parsedMinutes[3] < parsedMinutes[4], isTrue, reason: 'Asr < Maghrib failed for W$w on $dayKey');
          expect(parsedMinutes[4] < parsedMinutes[5], isTrue, reason: 'Maghrib < Isha failed for W$w on $dayKey');
        }
      }
    });
  });

  group('Forensic Stress Test: Astronomical Engine Future Dates & Invariants (2027)', () {
    test('Calculates valid schedules for 2027 future dates across all 58 Wilayas', () {
      final futureDates = [
        DateTime(2027, 1, 1),
        DateTime(2027, 3, 21),
        DateTime(2027, 6, 21),
        DateTime(2027, 9, 23),
        DateTime(2027, 10, 6),
        DateTime(2027, 12, 31),
      ];

      for (final date in futureDates) {
        for (final wilaya in algerianWilayas) {
          final schedule = AlgerianPrayerCalculator.calculateForWilaya(
            wilaya: wilaya,
            date: date,
          );

          expect(schedule.fajr.isBefore(schedule.sunrise), isTrue,
              reason: 'Fajr < Sunrise for Wilaya ${wilaya.code} on $date');
          expect(schedule.sunrise.isBefore(schedule.dhuhr), isTrue,
              reason: 'Sunrise < Dhuhr for Wilaya ${wilaya.code} on $date');
          expect(schedule.dhuhr.isBefore(schedule.asr), isTrue,
              reason: 'Dhuhr < Asr for Wilaya ${wilaya.code} on $date');
          expect(schedule.asr.isBefore(schedule.maghrib), isTrue,
              reason: 'Asr < Maghrib for Wilaya ${wilaya.code} on $date');
          expect(schedule.maghrib.isBefore(schedule.isha), isTrue,
              reason: 'Maghrib < Isha for Wilaya ${wilaya.code} on $date');
        }
      }
    });

    test('East-West gradient holds for future date 2027-06-21 (Summer Solstice)', () {
      final constantine = algerianWilayas.firstWhere((w) => w.code == 25);
      final alger = algerianWilayas.firstWhere((w) => w.code == 16);
      final oran = algerianWilayas.firstWhere((w) => w.code == 31);
      final date = DateTime(2027, 6, 21);

      final cst = AlgerianPrayerCalculator.calculateForWilaya(wilaya: constantine, date: date);
      final alg = AlgerianPrayerCalculator.calculateForWilaya(wilaya: alger, date: date);
      final ora = AlgerianPrayerCalculator.calculateForWilaya(wilaya: oran, date: date);

      expect(cst.fajr.isBefore(alg.fajr), isTrue);
      expect(alg.fajr.isBefore(ora.fajr), isTrue);
      expect(cst.maghrib.isBefore(alg.maghrib), isTrue);
      expect(alg.maghrib.isBefore(ora.maghrib), isTrue);
    });
  });

  group('Forensic Stress Test: Hijri Engine Boundaries', () {
    test('Correctly computes Hijri dates across multiple Gregorian years', () {
      final dates = [
        DateTime(2025, 1, 1),
        DateTime(2026, 1, 1),
        DateTime(2026, 10, 6),
        DateTime(2027, 1, 1),
        DateTime(2028, 2, 29), // Leap year
      ];

      for (final dt in dates) {
        final h = HijriCalculator.calculate(gregorianDate: dt);
        expect(h.year >= 1446 && h.year <= 1450, isTrue);
        expect(h.month >= 1 && h.month <= 12, isTrue);
        expect(h.day >= 1 && h.day <= 30, isTrue);
        expect(h.monthNameAr.isNotEmpty, isTrue);
        expect(h.dayNameAr.isNotEmpty, isTrue);
      }
    });

    test('Moonsighting adjustment clamping enforces [-2, +2]', () {
      final dt = DateTime(2026, 10, 6);
      final clampedPos = HijriCalculator.calculate(gregorianDate: dt, offsetDays: 10);
      expect(clampedPos.offsetDays, equals(2));

      final clampedNeg = HijriCalculator.calculate(gregorianDate: dt, offsetDays: -10);
      expect(clampedNeg.offsetDays, equals(-2));
    });
  });
}
